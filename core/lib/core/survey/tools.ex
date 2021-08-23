defmodule Core.Survey.Tools do
  @moduledoc """

  Survey tools allow a researcher to setup a link to an external survey
  tool. The participant goes through the flow described below:

  - Receive invitation to start a survey (mail, push etc.).
  - Open survey tool, this opens it on the platform and requires authentication.
  - The participant is then redirected to the survey at a 3rd party web-application.
  - After completion the user is redirect back to the platform.
  - The platform registers the completion of this survey for the participant.


  A researcher is required to configure the 3rd party application with a redirect
  link. The redirect link to be used is show on the survey tool configuration
  screen (with copy button).

  IDEA: The tool requires a sucessful round-trip with a verify flow to ensure
  that everything is configured correctly.

  Participants need to be invited to a particular survey explicitly. This avoids
  the situation where a new user joins a study and then can immediately complete
  previous surveys.

  Once a participant has completed a survey they are no longer allowed to enter it
  a second time. The status is clearly shown when the attempt to do so.

  IDEA: A list of surveys can be access by the notification icon which is shown
  on all screens.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Core.Repo

  alias Core.Accounts.User
  alias Core.Survey.{Tool, Task, Participant}
  alias Core.Authorization
  alias Core.Signals
  alias Core.Content.Nodes
  alias Core.Studies
  alias Core.Studies.Study

  @doc """
  Returns the list of survey_tools.
  """
  def list_survey_tools do
    Repo.all(Tool)
  end

  @doc """
  Gets a single survey_tool.

  Raises `Ecto.NoResultsError` if the Survey tool does not exist.
  """
  def get_survey_tool!(id), do: Repo.get!(Tool, id)
  def get_survey_tool(id), do: Repo.get(Tool, id)

  def get_by_promotion(promotion_id) do
    from(t in Tool,
      where: t.promotion_id == ^promotion_id
    )
    |> Repo.one()
  end

  @doc """
  Creates a survey_tool.
  """
  def create_survey_tool(attrs, study, promotion, content_node) do
    %Tool{}
    |> Tool.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(study))
    |> Repo.insert()
  end

  @doc """
  Updates a survey_tool.
  """
  def update_survey_tool(%Tool{} = survey_tool, type, attrs) do
    survey_tool
    |> Tool.changeset(type, attrs)
    |> update_survey_tool()
  end

  def update_survey_tool(_, _, _), do: nil

  def update_survey_tool(%{data: tool, changes: attrs} = changeset) do
    node = Nodes.get!(tool.content_node_id)
    node_changeset = Tool.node_changeset(node, tool, attrs)

    study = Studies.get_study!(tool.study_id)
    study_changeset = Study.changeset(study, %{updated_at: NaiveDateTime.utc_now()})

    Multi.new()
    |> Multi.update(:tool, changeset)
    |> Multi.update(:content_node, node_changeset)
    |> Multi.update(:study, study_changeset)
    |> Repo.transaction()
  end

  @doc """
  Deletes a survey_tool.
  """
  def delete_survey_tool(%Tool{} = survey_tool) do
    study = Core.Studies.get_study!(survey_tool.study_id)
    content_node = Core.Content.Nodes.get!(survey_tool.content_node_id)
    promotion = Core.Promotions.get!(survey_tool.promotion_id)

    Multi.new()
    |> Multi.delete(:study, study)
    |> Multi.delete(:promotion, promotion)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking survey_tool changes.
  """
  def change_survey_tool(%Tool{} = survey_tool, type, attrs \\ %{}) do
    Tool.changeset(survey_tool, type, attrs)
  end

  def create_task(survey_tool, user) do
    Repo.insert(%Task{tool: survey_tool, user: user, status: :pending})
  end

  def get_task(survey_tool, user) do
    Repo.get_by(Task, tool_id: survey_tool.id, user_id: user.id)
  end

  def get_or_create_task(survey_tool, user) do
    if participant?(survey_tool, user) do
      case get_task(survey_tool, user) do
        nil -> create_task(survey_tool, user)
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

  def list_tasks(survey_tool) do
    from(t in Task, where: t.tool_id == ^survey_tool.id)
    |> Repo.all()
  end

  def count_tasks(survey_tool, status_list) do
    case survey_tool.id do
      nil ->
        0

      _ ->
        from(t in Task,
          where: t.tool_id == ^survey_tool.id and t.status in ^status_list,
          select: count(t.id)
        )
        |> Repo.one()
    end
  end

  def count_pending_tasks(survey_tool) do
    count_tasks(survey_tool, [:pending])
  end

  def count_completed_tasks(survey_tool) do
    count_tasks(survey_tool, [:completed])
  end

  @spec participant?(
          atom | %{:id => any, optional(any) => any},
          atom | %{:id => any, optional(any) => any}
        ) :: boolean
  def participant?(survey_tool, user) do
    from(p in Core.Survey.Participant,
      where: p.survey_tool_id == ^survey_tool.id and p.user_id == ^user.id
    )
    |> Repo.exists?()
  end

  def list_participants_without_task(survey_tool) do
    user_ids_with_task = from(t in Task, where: t.tool_id == ^survey_tool.id, select: t.user_id)

    from(p in Participant,
      where: p.survey_tool_id == ^survey_tool.id and p.user_id not in subquery(user_ids_with_task)
    )
    |> Repo.all()
  end

  def setup_tasks_for_participants!(participants, survey_tool) do
    participants
    |> Enum.map(
      &(Task.changeset(%Task{}, %{status: :pending})
        |> Ecto.Changeset.put_change(:user_id, &1.user_id)
        |> Ecto.Changeset.put_assoc(:tool, survey_tool))
    )
    |> Enum.map(&Repo.insert!(&1))
  end

  def complete_task!(%Task{} = task) do
    task
    |> Task.changeset(%{status: :completed})
    |> Repo.update!()
  end

  def delete_task(%Task{} = task) do
    task
    |> Repo.delete()
  end

  def delete_task(_), do: nil

  # Participation
  # -------------
  def apply_participant(%Tool{} = survey_tool, %User{} = user) do
    Multi.new()
    |> Multi.insert(
      :participant,
      %Participant{}
      |> Participant.changeset()
      |> Ecto.Changeset.put_assoc(:survey_tool, survey_tool)
      |> Ecto.Changeset.put_assoc(:user, user)
    )
    |> Multi.insert(
      :role_assignment,
      Authorization.build_role_assignment(user, survey_tool, :participant)
    )
    |> Signals.multi_dispatch(:participant_applied, %{
      tool: survey_tool,
      user: user
    })
    |> Repo.transaction()
  end

  def list_participants(%Tool{} = survey_tool) do
    from(p in Participant,
      where: p.survey_tool_id == ^survey_tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_participations(%User{} = user) do
    from(s in Tool,
      join: p in Participant,
      on: s.id == p.survey_tool_id,
      where: p.user_id == ^user.id
    )
    |> Repo.all()
  end

  def withdraw_participant(%Tool{} = survey_tool, %User{} = user) do
    Multi.new()
    |> Multi.delete_all(
      :participant,
      from(p in Participant,
        where: p.survey_tool_id == ^survey_tool.id and p.user_id == ^user.id
      )
    )
    |> Multi.delete_all(
      :task,
      from(t in Task,
        where: t.tool_id == ^survey_tool.id
      )
    )
    |> Multi.delete_all(
      :role_assignment,
      Authorization.query_role_assignment(user, survey_tool, :participant)
    )
    |> Repo.transaction()
  end
end

defimpl Core.Persister, for: Core.Survey.Tool do
  def save(_tool, changeset) do
    Core.Survey.Tools.update_survey_tool(changeset)
  end
end
