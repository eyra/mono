defmodule Core.DataDonation.Tools do
  @moduledoc """

  A data donation allows a researcher to ask participants to submit data. This
  data is submitted in the form of a file that is stored on the participants
  device.

  Tools are provided that allow for execution of filtering code on the device
  of the participant. This ensures that only the data that is needed for the
  study is shared with the researcher.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Ecto.Multi
  alias Core.DataDonation.{Tool, Task, Participant, UserData}
  alias Core.Authorization
  alias Core.Accounts.User
  alias Core.Signals

  def list do
    Repo.all(Tool)
  end

  def get!(id), do: Repo.get!(Tool, id)
  def get(id), do: Repo.get(Tool, id)

  def get_by_promotion(promotion_id) do
    from(t in Tool,
      where: t.promotion_id == ^promotion_id
    )
    |> Repo.one()
  end

  def create(attrs, study, promotion, content_node) do
    %Tool{}
    |> Tool.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(study))
    |> Repo.insert()
  end

  def update(changeset) do
    changeset
    |> Repo.update()
  end

  def delete(%Tool{} = tool) do
    study = Core.Studies.get_study!(tool.study_id)
    content_node = Core.Content.Nodes.get!(tool.content_node_id)
    promotion = Core.Promotions.get!(tool.promotion_id)

    Multi.new()
    |> Multi.delete(:study, study)
    |> Multi.delete(:promotion, promotion)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  def participant?(tool, user) do
    from(p in Participant,
      where: p.tool_id == ^tool.id and p.user_id == ^user.id
    )
    |> Repo.exists?()
  end

  def apply_participant(%Tool{} = tool, %User{} = user) do
    Multi.new()
    |> Multi.insert(
      :participant,
      %Participant{}
      |> Participant.changeset()
      |> Ecto.Changeset.put_assoc(:tool, tool)
      |> Ecto.Changeset.put_assoc(:user, user)
    )
    |> Multi.insert(
      :role_assignment,
      Authorization.build_role_assignment(user, tool, :participant)
    )
    |> Signals.multi_dispatch(:participant_applied, %{
      tool: tool,
      user: user
    })
    |> Repo.transaction()
  end

  def list_participants(%Tool{} = tool) do
    from(p in Participant,
      where: p.tool_id == ^tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_participations(%User{} = user) do
    from(t in Tool,
      join: p in Participant,
      on: t.id == p.tool_id,
      where: p.user_id == ^user.id
    )
    |> Repo.all()
  end

  def withdraw_participant(%Tool{} = tool, %User{} = user) do
    Multi.new()
    |> Multi.delete_all(
      :participant,
      from(p in Participant,
        where: p.tool_id == ^tool.id and p.user_id == ^user.id
      )
    )
    |> Multi.delete_all(
      :task,
      from(t in Task,
        where: t.tool_id == ^tool.id
      )
    )
    |> Multi.delete_all(
      :role_assignment,
      Authorization.query_role_assignment(user, tool, :participant)
    )
    |> Repo.transaction()
  end

  def count_tasks(tool, status_list) do
    case tool.id do
      nil ->
        0

      _ ->
        from(t in Task,
          where: t.tool_id == ^tool.id and t.status in ^status_list,
          select: count(t.id)
        )
        |> Repo.one()
    end
  end

  def count_pending_tasks(tool) do
    count_tasks(tool, [:pending])
  end

  def count_completed_tasks(tool) do
    count_tasks(tool, [:completed])
  end

  def create_task(tool, user) do
    Repo.insert(%Task{tool: tool, user: user, status: :pending})
  end

  def get_task(tool, user) do
    Repo.get_by(Task, tool_id: tool.id, user_id: user.id)
  end

  def get_or_create_task(tool, user) do
    if participant?(tool, user) do
      case get_task(tool, user) do
        nil -> create_task(tool, user)
        task -> {:ok, task}
      end
    else
      {:error, :not_a_participant}
    end
  end

  def get_or_create_task!(survey_tool, user) do
    case get_or_create_task(survey_tool, user) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def list_donations(%Tool{} = tool) do
    from(u in UserData,
      where: u.tool_id == ^tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end
end
