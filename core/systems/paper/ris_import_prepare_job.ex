defmodule Systems.Paper.RISImportPrepareJob do
  use Oban.Worker, queue: :ris_import

  alias Core.Repo
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
    # Move to processing phase with signal
    {:ok, %{paper_ris_import_session: session}} =
      session
      |> Paper.RISImportSessionModel.advance_phase_with_signal(:processing)

    ris_entries = process_and_categorize_references(references, paper_set_id)
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

  defp process_and_categorize_references(references, paper_set_id) do
    paper_set = Repo.get!(Paper.SetModel, paper_set_id)
    processed = Paper.RISProcessor.process_references(references, paper_set)

    Enum.map(processed, fn
      {{:ok, :new, attrs}, _raw} ->
        RISEntry.new_paper(attrs)
        |> RISEntry.to_map()

      {{:ok, :existing, attrs, paper_id}, _raw} ->
        RISEntry.existing_paper(attrs, paper_id)
        |> RISEntry.to_map()

      {{:error, error}, _raw} ->
        RISEntry.error(error)
        |> RISEntry.to_map()
    end)
  end

  defp update_session_with_processed_data(session, ris_entries, summary) do
    session
    |> Paper.RISImportSessionModel.update_changeset(%{
      entries: ris_entries,
      import_summary: summary
    })
    |> Repo.update()
  end

  defp calculate_summary(ris_entries) do
    %{
      total: length(ris_entries),
      predicted_new: Enum.count(ris_entries, &(&1.status == "new")),
      predicted_existing: Enum.count(ris_entries, &(&1.status == "existing")),
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
