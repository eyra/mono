defmodule Systems.Zircon.Switch do
  use Frameworks.Signal.Handler

  alias Core.Repo
  alias Systems.Annotation
  alias Systems.Zircon

  def intercept(
        {:paper_reference_file, :updated},
        %{paper_reference_file: paper_reference_file}
      ) do
    zircon_screening_tool =
      Zircon.Public.get_screening_tool_by_reference_file!(paper_reference_file)

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

  defp update_criteria_view(model, from_pid) do
    dispatch!({:embedded_live_view, Zircon.Screening.CriteriaView}, %{
      id: model.id,
      model: model,
      from_pid: from_pid
    })
  end
end
