defmodule Systems.Assignment.ContributionsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Fund
  alias Systems.Workflow

  @section_keys [:pending, :declined, :confirmed]

  def view_model(
        %Assignment.Model{crew: %Crew.Model{} = crew, fund: %Fund.Model{} = fund} = assignment,
        %{} = assigns
      ) do
    context = %{
      fund: fund,
      members_by_user_id: members_by_user_id(crew),
      completed_task_counts_by_user_id:
        Crew.Public.task_status_counts_by_user(crew, [:completed]),
      total_task_count: total_task_count(assignment),
      participation_ids_by_user_id: participation_ids_by_user_id(assignment)
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

  defp section(:pending = key, %{fund: fund, completed_task_counts_by_user_id: counts} = context) do
    rows =
      fund
      |> Fund.Public.list_pending_approvals([])
      |> Enum.filter(fn %Fund.RewardModel{user_id: user_id} ->
        Map.get(counts, user_id, 0) > 0
      end)
      |> Enum.map(&row(key, &1, context))

    {key,
     %{
       module: Assignment.ContributionsPendingView,
       id: "contributions-pending",
       rows: rows,
       count: length(rows)
     }}
  end

  defp section(:declined = key, %{fund: fund} = context) do
    rewards =
      fund
      |> Fund.Public.list_rejected_rewards([])
      |> Enum.sort_by(& &1.rejected_at, {:desc, NaiveDateTime})

    case rewards do
      [] ->
        nil

      _ ->
        rows = Enum.map(rewards, &row(key, &1, context))

        {key,
         %{
           module: Assignment.ContributionsDeclinedView,
           id: "contributions-declined",
           rows: rows,
           count: length(rows)
         }}
    end
  end

  defp section(:confirmed = key, %{fund: fund} = context) do
    rows =
      fund
      |> Fund.Public.list_confirmed_rewards([])
      |> Enum.sort_by(& &1.id, :desc)
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
         %Fund.RewardModel{id: reward_id, user_id: user_id},
         %{
           completed_task_counts_by_user_id: counts,
           members_by_user_id: mbi,
           participation_ids_by_user_id: pids,
           total_task_count: total
         }
       ) do
    %{
      reward_id: reward_id,
      user_id: user_id,
      participation_id: Map.get(pids, user_id),
      member_public_id: member_public_id(mbi, user_id) || reward_id,
      completed_task_count: Map.get(counts, user_id, 0),
      total_task_count: total
    }
  end

  defp row(:confirmed, %Fund.RewardModel{id: reward_id, user_id: user_id}, %{
         members_by_user_id: mbi,
         participation_ids_by_user_id: pids
       }) do
    %{
      reward_id: reward_id,
      participation_id: Map.get(pids, user_id),
      member_public_id: member_public_id(mbi, user_id) || reward_id
    }
  end

  defp row(
         :declined,
         %Fund.RewardModel{
           id: reward_id,
           user_id: user_id,
           rejected_at: rejected_at,
           rejection_reason: rejection_reason
         },
         %{members_by_user_id: mbi, participation_ids_by_user_id: pids}
       ) do
    %{
      reward_id: reward_id,
      participation_id: Map.get(pids, user_id),
      member_public_id: member_public_id(mbi, user_id) || reward_id,
      rejected_at: rejected_at,
      rejection_reason: rejection_reason
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

  defp participation_ids_by_user_id(%Assignment.Model{} = assignment) do
    assignment
    |> Assignment.Public.list_participations()
    |> Map.new(fn %Assignment.ParticipationModel{user_id: user_id, id: id} -> {user_id, id} end)
  end

  defp member_public_id(members_by_user_id, user_id) do
    case Map.get(members_by_user_id, user_id) do
      %Crew.MemberModel{public_id: public_id} -> public_id
      nil -> nil
    end
  end
end
