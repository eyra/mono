defmodule Systems.Paper.RISImportPrepareJob do
  use Oban.Worker, queue: :ris_import

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Paper
  alias Systems.Paper.RISEntry

  defp fetcher_module do
    Application.get_env(:core, :ris_fetcher_module, Systems.Paper.RISFetcherHTTP)
  end

  @impl true
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    # Get the import session with all needed associations
    session =
      Repo.get!(Paper.RISImportSessionModel, session_id)
      |> Repo.preload([:paper_set, reference_file: :file])

    # Process the file
    process_file(session)
  end

  defp process_file(%{reference_file: reference_file} = session) do
    # Fetch RIS content
    case fetcher_module().fetch_content(reference_file) do
      {:ok, ris_content} ->
        process_ris_content(session, ris_content)

      {:error, error} ->
        handle_error(session, error)
    end
  end

  defp process_ris_content(session, ris_content) do
    # Transition from waiting to parsing phase with signal
    {:ok, %{paper_ris_import_session: session}} =
      session
      |> Paper.RISImportSessionModel.advance_phase_with_signal(:parsing)

    references = Paper.RISParser.parse_content(ris_content)
    handle_successful_parse(session, references)
  end

  defp handle_successful_parse(%{paper_set_id: paper_set_id} = session, references) do
    # Store the total reference count in progress before transitioning to processing
    total_references = length(references)

    # Update session with initial progress info and move to processing phase atomically
    {:ok, %{paper_ris_import_session: session}} =
      Multi.new()
      |> Multi.update(
        :paper_ris_import_session,
        Paper.RISImportSessionModel.update_changeset(session, %{
          progress: %{"total_references" => total_references, "current_reference" => 0},
          phase: :processing
        })
      )
      |> Frameworks.Signal.Public.multi_dispatch({:paper_ris_import_session, :processing})
      |> Repo.commit()

    ris_entries = process_and_categorize_references(references, paper_set_id, session)
    summary = calculate_summary(ris_entries)

    case update_session_with_processed_data(session, ris_entries, summary) do
      {:ok, updated_session} ->
        # Move to prompting phase after processing is complete
        {:ok, %{paper_ris_import_session: _final_session}} =
          updated_session
          |> Paper.RISImportSessionModel.advance_phase_with_signal(:prompting)

        :ok

      {:error, changeset} ->
        # For database update failures, we want Oban to retry the job
        # Most database errors (connection issues, locks) are transient
        # Validation errors indicate data issues that likely won't resolve on retry
        if has_validation_errors?(changeset) do
          # Data validation failed - discard the job as retrying won't help
          {:discard, "Data validation failed: #{format_changeset_errors(changeset)}"}
        else
          # Database error - let Oban retry with exponential backoff
          {:error, "Database update failed: #{format_changeset_errors(changeset)}"}
        end
    end
  end

  defp process_and_categorize_references(references, paper_set_id, session) do
    paper_set = Repo.get!(Paper.SetModel, paper_set_id)
    total_references = length(references)

    # Process references with progress updates
    {processed_entries, _} =
      references
      |> Enum.with_index(1)
      |> Enum.map(fn {reference, index} ->
        # Update progress periodically (every 10 references or on specific milestones)
        if rem(index, 10) == 0 or index == 1 or index == total_references do
          update_processing_progress(session, index, total_references)
        end

        # Process this reference
        processed = Paper.RISProcessor.process_references([reference], paper_set)

        case List.first(processed) do
          {{:ok, :new, attrs}, _raw} ->
            RISEntry.new_paper(attrs)
            |> RISEntry.to_map()

          {{:ok, :existing, attrs, paper_id}, _raw} ->
            RISEntry.existing_paper(attrs, paper_id)
            |> RISEntry.to_map()

          {{:error, error}, _raw} ->
            RISEntry.error(error)
            |> RISEntry.to_map()

          nil ->
            # This shouldn't happen but handle gracefully
            RISEntry.error(%{message: "Failed to process reference"})
            |> RISEntry.to_map()
        end
      end)
      |> Enum.reduce({[], 0}, fn entry, {acc, count} ->
        {[entry | acc], count + 1}
      end)

    Enum.reverse(processed_entries)
  end

  defp update_processing_progress(session, current_reference, total_references) do
    progress = %{
      "current_reference" => current_reference,
      "total_references" => total_references
    }

    # Use Multi for atomic update and signal dispatch
    Multi.new()
    |> Multi.update(
      :paper_ris_import_session,
      Paper.RISImportSessionModel.update_changeset(session, %{progress: progress})
    )
    |> Frameworks.Signal.Public.multi_dispatch({:paper_ris_import_session, :processing_progress})
    |> Repo.commit()
  end

  defp update_session_with_processed_data(session, ris_entries, summary) do
    session
    |> Paper.RISImportSessionModel.update_changeset(%{
      entries: ris_entries,
      summary: summary
    })
    |> Repo.update()
  end

  defp calculate_summary(ris_entries) do
    %{
      total: length(ris_entries),
      predicted_new: Enum.count(ris_entries, &(&1.status == "new")),
      predicted_existing: Enum.count(ris_entries, &(&1.status == "duplicate")),
      predicted_errors: Enum.count(ris_entries, &(&1.status == "error")),
      # These will be updated during import
      imported: 0,
      skipped_duplicates: 0
    }
  end

  defp has_validation_errors?(changeset) do
    # Check if the changeset has validation errors (as opposed to database constraint errors)
    changeset.errors
    |> Enum.any?(fn {_field, {_message, metadata}} ->
      # Validation errors typically have validation: true in metadata
      Keyword.get(metadata, :validation, false)
    end)
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map_join(", ", fn {field, {message, _}} -> "#{field}: #{message}" end)
  end

  defp handle_error(session, error) do
    handle_session_error(session, error)
  end

  defp handle_session_error(%{errors: errors, reference_file: reference_file} = session, error) do
    error_message =
      case error do
        message when is_binary(message) -> message
        _ -> inspect(error)
      end

    # Mark session as failed
    Paper.RISImportSessionModel.mark_failed_with_signal!(session, %{
      errors: [error_message | errors]
    })

    # Mark reference file as failed
    ris_error = %Paper.RISError{message: error_message}
    Paper.Public.mark_as_failed!(reference_file, ris_error)

    {:error, error_message}
  end
end
