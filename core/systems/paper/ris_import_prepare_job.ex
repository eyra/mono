defmodule Systems.Paper.RISImportPrepareJob do
  use Oban.Worker, queue: :ris_import
  use Gettext, backend: CoreWeb.Gettext

  require Logger

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Paper
  alias Systems.Paper.RISEntry

  @impl true
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    # Get the import session with all needed associations
    session =
      Repo.get!(Paper.RISImportSessionModel, session_id)
      |> Repo.preload([:paper_set, reference_file: :file])

    # Don't process if session is already failed or aborted
    case session.status do
      :failed ->
        {:discard, "Session already failed"}

      :aborted ->
        {:discard, "Session was aborted"}

      :succeeded ->
        {:discard, "Session already succeeded"}

      :activated ->
        # Process the file
        process_file(session)
    end
  end

  defp process_file(%{reference_file: reference_file} = session) do
    # Always use streaming for consistent behavior and memory efficiency

    # Transition to parsing phase
    {:ok, %{paper_ris_import_session: session}} =
      session
      |> Paper.RISImportSessionModel.advance_phase_with_signal(:parsing)

    # Get stream from fetcher using configured backend
    case Systems.Paper.RISFetcherBackendStream.fetch_content(reference_file) do
      {:ok, content_stream} ->
        process_ris_stream(session, content_stream)

      {:error, error} ->
        handle_fetch_error(session, error)
    end
  end

  defp process_ris_stream(%{paper_set_id: paper_set_id} = session, content_stream) do
    paper_set = Repo.get!(Paper.SetModel, paper_set_id)

    # Transition to processing phase
    {:ok, %{paper_ris_import_session: session}} =
      session
      |> Paper.RISImportSessionModel.advance_phase_with_signal(:processing)

    # First, collect all parsed entries to know the total count
    parsed_entries =
      content_stream
      |> Systems.Paper.RISParserStream.parse_stream_with_validation()
      |> Enum.to_list()

    total_references = length(parsed_entries)

    # Now process them with proper progress tracking
    {ris_entries, total_count, file_validation_error} =
      parsed_entries
      |> Enum.with_index(1)
      |> Enum.reduce({[], 0, nil}, fn
        {{:ok, {attrs, _raw}}, index}, {entries, _, validation_error} ->
          if rem(index, 10) == 0 or index == 1 do
            update_processing_progress(session, index, total_references)
          end

          # Process this reference (check for duplicates, etc.)
          processed = process_single_reference(attrs, paper_set)
          entry_map = reference_to_entry_map(processed)

          {[entry_map | entries], index, validation_error}

        {{:error, {error, _raw}}, index}, {entries, _, validation_error} ->
          # Check if this is a file-level validation error
          validation_error =
            if Map.get(error, :type) == :validation_error and index == 1 and entries == [] do
              error
            else
              validation_error
            end

          # Convert error to entry map format
          error_entry = RISEntry.error(error) |> RISEntry.to_map()
          {[error_entry | entries], index, validation_error}
      end)

    # Check for file-level validation error (entire file invalid)
    if file_validation_error do
      # Fail the session with validation error
      error_message = Map.get(file_validation_error, :message, "Invalid file format")
      fail_session_with_error(session, error_message)
    else
      # Continue with normal processing
      # Reverse to maintain original order
      final_entries = Enum.reverse(ris_entries)
      summary = calculate_summary(final_entries)

      # Update final progress and reload session
      session =
        if total_count > 0 do
          {:ok, %{paper_ris_import_session: updated_session}} =
            update_processing_progress(session, total_count, total_references)

          updated_session
        else
          session
        end

      # Update session with results
      case update_session_with_processed_data(session, final_entries, summary) do
        {:ok, updated_session} ->
          # Move to prompting phase
          {:ok, %{paper_ris_import_session: _final_session}} =
            updated_session
            |> Paper.RISImportSessionModel.advance_phase_with_signal(:prompting)

          :ok

        {:error, changeset} ->
          handle_database_error(changeset)
      end
    end
  end

  defp process_single_reference(attrs, paper_set) do
    case Paper.Private.check_paper_exists(attrs, paper_set) do
      {:existing, paper} ->
        {:existing, attrs, paper.id}

      :new ->
        {:new, attrs}
    end
  end

  defp reference_to_entry_map({:new, attrs}) do
    RISEntry.new_paper(attrs) |> RISEntry.to_map()
  end

  defp reference_to_entry_map({:existing, attrs, paper_id}) do
    RISEntry.existing_paper(attrs, paper_id) |> RISEntry.to_map()
  end

  defp handle_database_error(changeset) do
    if has_validation_errors?(changeset) do
      {:discard, "Data validation failed: #{format_changeset_errors(changeset)}"}
    else
      {:error, "Database update failed: #{format_changeset_errors(changeset)}"}
    end
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

  defp handle_fetch_error(%{errors: errors, reference_file: reference_file} = session, error) do
    Logger.error("Failed to fetch file: #{inspect(error)}")
    error_message = dgettext("eyra-content", "file.error.fetch_failed")

    # Mark session as failed
    Paper.RISImportSessionModel.mark_failed_with_signal!(session, %{
      errors: [error_message | errors]
    })

    # Mark reference file as failed
    ris_error = %Paper.RISError{message: error_message}
    Paper.Public.mark_as_failed!(reference_file, ris_error)

    # Return :discard to prevent Oban from retrying
    {:discard, error_message}
  end

  defp fail_session_with_error(session, error_message) do
    # Extract existing errors if any
    errors = Map.get(session, :errors, [])

    # Mark session as failed
    Paper.RISImportSessionModel.mark_failed_with_signal!(session, %{
      errors: [error_message | errors]
    })

    # Get reference file and mark it as failed
    reference_file = Core.Repo.get!(Paper.ReferenceFileModel, session.reference_file_id)
    ris_error = %Paper.RISError{message: error_message}
    Paper.Public.mark_as_failed!(reference_file, ris_error)

    # Return :discard to prevent Oban from retrying
    {:discard, error_message}
  end
end
