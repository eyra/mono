defmodule Link.Survey.MonitorData do
  use Ecto.Schema

  alias Core.Survey.Tools
  alias Core.Pools.Submissions

  embedded_schema do
    field(:is_active, :boolean)
    field(:subject_pending_count, :integer)
    field(:subject_completed_count, :integer)
    field(:subject_vacant_count, :integer)
  end

  def create(tool, promotion) do
    submission = Submissions.get!(promotion)
    is_active = submission.status === :accepted
    completed = Tools.count_completed_tasks(tool)
    pending = Tools.count_pending_tasks(tool)

    subject_vacant_count = tool |> get_subject_vacant_count(completed, pending)

    opts =
      %{}
      |> Map.put(:is_active, is_active)
      |> Map.put(:subject_pending_count, pending)
      |> Map.put(:subject_completed_count, completed)
      |> Map.put(:subject_vacant_count, subject_vacant_count)

    struct(Link.Survey.MonitorData, opts)
  end

  defp get_subject_vacant_count(survey_tool, completed, pending) do
    case survey_tool.subject_count do
      count when is_nil(count) -> 0
      count when count > 0 -> count - (completed + pending)
      _ -> 0
    end
  end
end
