defmodule Systems.Zircon.Switch do
  use Frameworks.Signal.Handler

  alias Core.Repo
  alias Systems.Annotation
  alias Systems.Observatory
  alias Systems.Paper
  alias Systems.Zircon

  def intercept(
        {:paper_reference_file, :updated},
        %{paper_reference_file: paper_reference_file, from_pid: from_pid}
      ) do
    zircon_screening_tool =
      Zircon.Public.get_screening_tool_by_reference_file!(paper_reference_file)

    Zircon.Public.invalidate_screening_sessions(zircon_screening_tool)

    # Update the ImportView to reflect the changed reference file
    update_import_view(zircon_screening_tool, from_pid)

    {:continue, :zircon_screening_tool, zircon_screening_tool}
  end

  def intercept(
        {:zircon_screening_tool_annotation_assoc, :inserted},
        %{zircon_screening_tool_annotation_assoc: %{tool: tool}, from_pid: from_pid}
      ) do
    tool = tool |> Repo.preload([annotations: Annotation.Model.preload_graph(:down)], force: true)
    update_criteria_view(tool, from_pid)

    :ok
  end

  def intercept(
        {:zircon_screening_tool_annotation_assoc, :deleted},
        %{zircon_screening_tool: tool, from_pid: from_pid}
      ) do
    tool = tool |> Repo.preload([annotations: Annotation.Model.preload_graph(:down)], force: true)
    update_criteria_view(tool, from_pid)

    :ok
  end

  def intercept(
        {:zircon_screening_sessions, :invalidated},
        %{zircon_screening_sessions: sessions, from_pid: _from_pid}
      ) do
    # TODO: update screening sessions
    "sessions invalidated: #{inspect(sessions)}"
    :ok
  end

  # Handle batch progress updates during import
  def intercept(
        {:paper_ris_import_session, :batch_completed},
        %{
          update_progress_with_counts: session,
          from_pid: from_pid
        } = _message
      ) do
    # Extract reference_file_id and progress from the updated session
    %{reference_file_id: reference_file_id, progress: progress} = session

    # Get the tool from the reference file
    reference_file = Paper.Public.get_reference_file!(reference_file_id)
    tool = Zircon.Public.get_screening_tool_by_reference_file!(reference_file)

    # The progress field now has all cumulative counts
    batch_progress = %{
      batch_num: Map.get(progress, "current_batch"),
      total_batches: Map.get(progress, "total_batches"),
      papers_processed: Map.get(progress, "papers_processed"),
      papers_imported: Map.get(progress, "papers_imported"),
      papers_skipped: Map.get(progress, "papers_skipped"),
      total_papers: Map.get(progress, "total_papers")
    }

    # Update the ImportView with batch progress info
    # The view model builder can use this to show progress
    Observatory.Public.collect_update(
      {:embedded_live_view, Zircon.Screening.ImportView},
      [tool.id],
      %{
        model: tool,
        batch_progress: batch_progress,
        from_pid: from_pid
      }
    )

    :ok
  end

  # Handle all paper_ris_import_session status changes
  def intercept(
        {:paper_ris_import_session, status},
        %{
          paper_ris_import_session: %{reference_file_id: reference_file_id} = session,
          from_pid: from_pid
        } = _message
      ) do
    update_import_session_view(session, from_pid)

    # Always update import_view to show current status
    reference_file = Paper.Public.get_reference_file!(reference_file_id)
    tool = Zircon.Public.get_screening_tool_by_reference_file!(reference_file)
    update_import_view(tool, from_pid)

    # Only update paper set view on successful completion
    if status == :succeeded do
      # Get the paper_set associated with the tool with papers preloaded
      paper_set =
        Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)
        |> Core.Repo.preload([:papers])

      update_paper_set_view(paper_set, from_pid)
    end

    :ok
  end

  # Handle paper_set updates (e.g., when papers are deleted)
  def intercept(
        {:paper_set, :updated},
        %{paper_set: paper_set, from_pid: from_pid}
      ) do
    # Update the paper set view itself (paper_set from signal already has papers preloaded)
    update_paper_set_view(paper_set, from_pid)

    # Also update the ImportView to refresh the paper count
    # The paper_set category is :zircon_screening_tool and identifier is the tool_id
    if paper_set.category == :zircon_screening_tool do
      tool = Zircon.Public.get_screening_tool!(paper_set.identifier)
      update_import_view(tool, from_pid)
    end

    :ok
  end

  defp update_criteria_view(model, from_pid) do
    Observatory.Public.collect_update(
      {:embedded_live_view, Zircon.Screening.CriteriaView},
      [model.id],
      %{
        model: model,
        from_pid: from_pid
      }
    )
  end

  defp update_import_view(model, from_pid) do
    Observatory.Public.collect_update(
      {:embedded_live_view, Zircon.Screening.ImportView},
      [model.id],
      %{
        model: model,
        from_pid: from_pid
      }
    )
  end

  defp update_paper_set_view(paper_set, from_pid) do
    Observatory.Public.collect_update(
      {:embedded_live_view, Zircon.Screening.PaperSetView},
      [paper_set.id],
      %{
        model: paper_set,
        from_pid: from_pid
      }
    )
  end

  defp update_import_session_view(model, from_pid) do
    Observatory.Public.collect_update(
      {:embedded_live_view, Zircon.Screening.ImportSessionView},
      [model.id],
      %{
        model: model,
        from_pid: from_pid
      }
    )
  end
end
