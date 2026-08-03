defmodule Systems.Assignment.ContributionsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  @section_keys [:pending, :declined, :confirmed]

  def view_model(
        %Assignment.Model{crew: %Crew.Model{} = crew} = assignment,
        %{} = assigns
      ) do
    context = %{
      assignment: assignment,
      members_by_user_id: members_by_user_id(crew),
      completed_task_counts_by_user_id:
        Crew.Public.task_status_counts_by_user(crew, [:completed]),
      total_task_count: total_task_count(assignment)
    }

    %{
      title: Map.get(assigns, :title, ""),
      sections: sections(context)
    }
  end

  defp sections(context) do
    @section_keys
    |> Enum.map(&section(&1, context))
    |> Enum.reject(&is_nil/1)
  end

  defp section(:pending = key, %{assignment: assignment} = context) do
    rows =
      assignment
      |> Assignment.Public.list_pending_participations()
      |> Enum.map(&row(key, &1, context))

    {key,
     %{
       module: Assignment.ContributionsPendingView,
       id: "contributions-pending",
       rows: rows,
       count: length(rows)
     }}
  end

  defp section(:declined = key, %{assignment: assignment} = context) do
    rejected = Assignment.Public.list_rejected_participations(assignment)

    case rejected do
      [] ->
        nil

      _ ->
        rows = Enum.map(rejected, &row(key, &1, context))

        {key,
         %{
           module: Assignment.ContributionsDeclinedView,
           id: "contributions-declined",
           rows: rows,
           count: length(rows)
         }}
    end
  end

  defp section(:confirmed = key, %{assignment: assignment} = context) do
    rows =
      assignment
      |> Assignment.Public.list_accepted_participations()
      |> Enum.map(&row(key, &1, context))

    {key,
     %{
       module: Assignment.ContributionsConfirmedView,
       id: "contributions-confirmed",
       rows: rows,
       count: length(rows)
     }}
  end

  defp row(
         :pending,
         %Assignment.ParticipationModel{id: id, user_id: user_id},
         %{
           completed_task_counts_by_user_id: counts,
           members_by_user_id: mbi,
           total_task_count: total
         }
       ) do
    %{
      participation_id: id,
      member_public_id: member_public_id(mbi, user_id) || id,
      completed_task_count: Map.get(counts, user_id, 0),
      total_task_count: total
    }
  end

  defp row(:confirmed, %Assignment.ParticipationModel{id: id, user_id: user_id}, %{
         members_by_user_id: mbi
       }) do
    %{
      participation_id: id,
      member_public_id: member_public_id(mbi, user_id) || id
    }
  end

  defp row(
         :declined,
         %Assignment.ParticipationModel{
           id: id,
           user_id: user_id,
           rejected_at: rejected_at,
           rejected_message: rejected_message
         },
         %{members_by_user_id: mbi}
       ) do
    %{
      participation_id: id,
      member_public_id: member_public_id(mbi, user_id) || id,
      rejected_at: rejected_at,
      rejection_reason: rejected_message
    }
  end

  defp total_task_count(%Assignment.Model{workflow: %Workflow.Model{items: items}})
       when is_list(items),
       do: length(items)

  defp total_task_count(_), do: 0

  defp members_by_user_id(%Crew.Model{} = crew) do
    crew
    |> Crew.Public.list_members()
    |> Map.new(fn %Crew.MemberModel{user_id: user_id} = member -> {user_id, member} end)
  end

  defp member_public_id(members_by_user_id, user_id) do
    case Map.get(members_by_user_id, user_id) do
      %Crew.MemberModel{public_id: public_id} -> public_id
      nil -> nil
    end
  end
end
