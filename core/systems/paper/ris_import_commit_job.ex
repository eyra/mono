defmodule Systems.Paper.RISImportCommitJob do
  use Oban.Worker, queue: :ris_import

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Paper

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"session_id" => session_id}}) do
    session = Paper.Public.get_import_session!(session_id, [:reference_file, :paper_set])

    # Session should already be in importing phase (set by commit_import_session!)
    # Just proceed with the import work

    # Extract new papers from session entries
    candidate_papers = extract_new_papers_from_session(session)

    # Execute the import
    case execute_import_transaction(candidate_papers, session) do
      {:ok, result} ->
        summary = update_import_summary(session.summary, result)
        complete_session_with_signal(session, summary)
        :ok

      {:error, error} ->
        handle_import_error_with_signal(session, "Import failed: #{error}")
        {:error, error}
    end
  end

  defp extract_new_papers_from_session(%{entries: entries}) do
    entries
    |> Enum.map(&Paper.RISEntry.from_map/1)
    |> Enum.filter(fn
      %{status: "new"} -> true
      _ -> false
    end)
  end

  defp execute_import_transaction(candidate_papers, session) do
    batch_size = Paper.Config.import_batch_size()
    total_papers = length(candidate_papers)
    total_batches = ceil(total_papers / batch_size)

    candidate_papers
    |> Enum.chunk_every(batch_size)
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, %{inserted: 0, skipped: 0, processed: 0}}, fn {batch, batch_num},
                                                                             {:ok, totals} ->
      papers_processed_so_far = totals.processed + length(batch)

      case execute_batch_transaction(
             batch,
             session,
             batch_num,
             total_batches,
             totals,
             papers_processed_so_far,
             total_papers
           ) do
        {:ok, batch_result} ->
          new_totals = %{
            inserted: totals.inserted + batch_result.inserted,
            skipped: totals.skipped + batch_result.skipped,
            processed: papers_processed_so_far
          }

          {:cont, {:ok, new_totals}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp execute_batch_transaction(
         batch,
         session,
         batch_num,
         total_batches,
         current_totals,
         papers_processed,
         total_papers
       ) do
    batch_timeout = Paper.Config.import_batch_timeout()

    {multi, paper_keys} =
      Multi.new()
      |> build_paper_insertion_multi(batch, session.paper_set)

    multi
    |> add_reference_file_associations(paper_keys, batch, session)
    |> Multi.run(:update_progress_with_counts, fn _repo, changes ->
      # Get the actual counts from the associate_papers result
      %{inserted: batch_inserted, skipped: batch_skipped} =
        Map.get(changes, :associate_papers, %{inserted: 0, skipped: 0})

      # Build final progress with cumulative counts
      final_progress = %{
        "current_batch" => batch_num,
        "total_batches" => total_batches,
        "papers_processed" => papers_processed,
        "papers_imported" => current_totals.inserted + batch_inserted,
        "papers_skipped" => current_totals.skipped + batch_skipped,
        "total_papers" => total_papers
      }

      # Update session with final progress
      session
      |> Paper.RISImportSessionModel.changeset(%{progress: final_progress})
      |> Repo.update()
    end)
    |> Frameworks.Signal.Public.multi_dispatch({:paper_ris_import_session, :batch_completed})
    |> Repo.commit(timeout: batch_timeout)
    |> case do
      {:ok, changes} ->
        result = Map.get(changes, :associate_papers, %{inserted: 0, skipped: 0})
        {:ok, result}

      {:error, _operation, changeset, _changes} ->
        error = format_changeset_errors(changeset)
        {:error, error}
    end
  end

  defp build_paper_insertion_multi(multi, candidate_papers, paper_set) do
    Enum.with_index(candidate_papers)
    |> Enum.reduce({multi, []}, fn {ref, index}, {multi, keys} ->
      paper_key = "check_and_insert_#{index}"

      multi =
        Multi.run(multi, paper_key, fn _repo, _changes ->
          attempt_paper_insertion(ref, paper_set)
        end)

      {multi, [paper_key | keys]}
    end)
  end

  defp attempt_paper_insertion(ref, paper_set) do
    case Paper.Private.check_paper_exists(ref, paper_set) do
      {:existing, paper} ->
        {:ok, {:skipped, paper}}

      :new ->
        changeset = Paper.RISProcessor.build_paper_changeset(ref, paper_set)

        case Repo.insert(changeset) do
          {:ok, paper} -> {:ok, {:inserted, paper}}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  defp add_reference_file_associations(multi, paper_keys, candidate_papers, session) do
    Multi.run(multi, :associate_papers, fn _repo, changes ->
      inserted_papers = extract_inserted_papers(changes, paper_keys)
      create_reference_file_associations(inserted_papers, candidate_papers, session)
    end)
  end

  defp extract_inserted_papers(changes, paper_keys) do
    paper_keys
    |> Enum.map(&Map.get(changes, &1))
    |> Enum.filter(fn
      {:inserted, _paper} -> true
      _ -> false
    end)
    |> Enum.map(fn {:inserted, paper} -> paper end)
  end

  defp create_reference_file_associations(inserted_papers, candidate_papers, session) do
    if Enum.empty?(inserted_papers) do
      {:ok, %{inserted: 0, skipped: length(candidate_papers)}}
    else
      association_results = Enum.map(inserted_papers, &create_paper_association(&1, session))

      successful_associations = Enum.count(association_results, &(&1 == :ok))
      failed_associations = Enum.count(association_results, &(&1 == :error))

      if failed_associations > 0 do
        {:error, "Some paper associations failed"}
      else
        {:ok,
         %{
           inserted: successful_associations,
           skipped: length(candidate_papers) - length(inserted_papers)
         }}
      end
    end
  end

  defp create_paper_association(paper, session) do
    assoc_changeset =
      %Paper.ReferenceFilePaperAssoc{}
      |> Ecto.Changeset.change(%{
        reference_file_id: session.reference_file_id,
        paper_id: paper.id
      })

    case Repo.insert(assoc_changeset) do
      {:ok, _assoc} -> :ok
      {:error, _changeset} -> :error
    end
  end

  defp update_import_summary(existing_summary, result) do
    existing_summary
    |> Map.put("imported", result.inserted)
    |> Map.put("skipped_duplicates", result.skipped)
  end

  defp complete_session_with_signal(session, summary) do
    reference_file = Repo.get!(Paper.ReferenceFileModel, session.reference_file_id)

    # Complete session and update reference file in a single transaction
    multi = Multi.new()

    multi =
      Multi.run(multi, :session, fn _repo, _changes ->
        case Paper.RISImportSessionModel.mark_succeeded_with_signal(session, %{
               summary: summary
             }) do
          {:ok, %{paper_ris_import_session: updated_session}} -> {:ok, updated_session}
          {:error, error} -> {:error, error}
        end
      end)

    multi =
      Multi.update(multi, :reference_file, fn %{session: _session} ->
        Paper.ReferenceFileModel.changeset(reference_file, %{status: :archived})
      end)

    case Repo.commit(multi) do
      {:ok, %{session: updated_session, reference_file: _updated_ref_file}} ->
        {:ok, updated_session}

      {:error, _operation, error, _changes} ->
        {:error, error}
    end
  end

  defp handle_import_error_with_signal(session, error_message) do
    reference_file = Repo.get!(Paper.ReferenceFileModel, session.reference_file_id)

    # Mark session as failed and reference file as failed in a single transaction
    multi = Multi.new()

    multi =
      Multi.run(multi, :session, fn _repo, _changes ->
        case Paper.RISImportSessionModel.mark_failed_with_signal(session, %{
               errors: [error_message | session.errors]
             }) do
          {:ok, %{paper_ris_import_session: updated_session}} -> {:ok, updated_session}
          {:error, error} -> {:error, error}
        end
      end)

    multi =
      Multi.update(multi, :reference_file, fn %{session: _session} ->
        Paper.ReferenceFileModel.changeset(reference_file, %{status: :failed})
      end)

    case Repo.commit(multi) do
      {:ok, %{session: _updated_session}} ->
        {:error, error_message}

      {:error, _operation, error, _changes} ->
        {:error, "Failed to update session and reference file: #{inspect(error)}"}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
  end
end
