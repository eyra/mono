defmodule Link.SurveyTools do
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
  alias Link.Repo

  alias Link.Users.User
  alias Link.SurveyTools.{SurveyTool, SurveyToolTask, Participant}
  alias Link.Authorization

  @doc """
  Returns the list of survey_tools.

  ## Examples

      iex> list_survey_tools()
      [%SurveyTool{}, ...]

  """
  def list_survey_tools do
    Repo.all(SurveyTool)
  end

  @doc """
  Gets a single survey_tool.

  Raises `Ecto.NoResultsError` if the Survey tool does not exist.

  ## Examples

      iex> get_survey_tool!(123)
      %SurveyTool{}

      iex> get_survey_tool!(456)
      ** (Ecto.NoResultsError)

  """
  def get_survey_tool!(id), do: Repo.get!(SurveyTool, id)
  def get_survey_tool(id), do: Repo.get(SurveyTool, id)

  @doc """
  Creates a survey_tool.

  ## Examples

      iex> create_survey_tool(%{field: value})
      {:ok, %SurveyTool{}}

      iex> create_survey_tool(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_survey_tool(attrs, study) do
    %SurveyTool{}
    |> SurveyTool.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(study))
    |> Repo.insert()
  end

  @doc """
  Updates a survey_tool.

  ## Examples

      iex> update_survey_tool(survey_tool, %{field: new_value})
      {:ok, %SurveyTool{}}

      iex> update_survey_tool(survey_tool, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_survey_tool(%SurveyTool{} = survey_tool, attrs) do
    survey_tool
    |> SurveyTool.changeset(attrs)
    |> update_survey_tool()
  end

  def update_survey_tool(_, _), do: nil

  def update_survey_tool(changeset) do
    changeset
    |> Repo.update()
  end

  @doc """
  Deletes a survey_tool.

  ## Examples

      iex> delete_survey_tool(survey_tool)
      {:ok, %SurveyTool{}}

      iex> delete_survey_tool(survey_tool)
      {:error, %Ecto.Changeset{}}

  """
  def delete_survey_tool(%SurveyTool{} = survey_tool) do
    Repo.delete(survey_tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking survey_tool changes.

  ## Examples

      iex> change_survey_tool(survey_tool)
      %Ecto.Changeset{data: %SurveyTool{}}

  """
  def change_survey_tool(%SurveyTool{} = survey_tool, attrs \\ %{}) do
    SurveyTool.changeset(survey_tool, attrs)
  end

  def create_task(survey_tool, user) do
    Repo.insert(%SurveyToolTask{survey_tool: survey_tool, user: user, status: :pending})
  end

  def get_task(survey_tool, user) do
    Repo.get_by(SurveyToolTask, survey_tool_id: survey_tool.id, user_id: user.id)
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
    from(t in SurveyToolTask, where: t.survey_tool_id == ^survey_tool.id)
    |> Repo.all()
  end

  def count_pending_tasks(survey_tool) do
    case survey_tool.id do
      nil ->
        0

      _ ->
        from(t in SurveyToolTask,
          where: t.survey_tool_id == ^survey_tool.id and t.status == :pending,
          select: count(t.id)
        )
        |> Repo.one()
    end
  end

  def count_completed_tasks(survey_tool) do
    case survey_tool.id do
      nil ->
        0

      _ ->
        from(t in SurveyToolTask,
          where: t.survey_tool_id == ^survey_tool.id and t.status == :completed,
          select: count(t.id)
        )
        |> Repo.one()
    end
  end

  @spec participant?(
          atom | %{:id => any, optional(any) => any},
          atom | %{:id => any, optional(any) => any}
        ) :: boolean
  def participant?(survey_tool, user) do
    from(p in Link.SurveyTools.Participant,
      where: p.survey_tool_id == ^survey_tool.id and p.user_id == ^user.id
    )
    |> Repo.exists?()
  end

  def list_participants_without_task(survey_tool) do
    user_ids_with_task =
      from(t in SurveyToolTask, where: t.survey_tool_id == ^survey_tool.id, select: t.user_id)

    from(p in Participant,
      where: p.survey_tool_id == ^survey_tool.id and p.user_id not in subquery(user_ids_with_task)
    )
    |> Repo.all()
  end

  def setup_tasks_for_participants!(participants, survey_tool) do
    participants
    |> Enum.map(
      &(SurveyToolTask.changeset(%SurveyToolTask{}, %{status: :pending})
        |> Ecto.Changeset.put_change(:user_id, &1.user_id)
        |> Ecto.Changeset.put_assoc(:survey_tool, survey_tool))
    )
    |> Enum.map(&Repo.insert!(&1))
  end

  def complete_task!(task) do
    task
    |> SurveyToolTask.changeset(%{status: :completed})
    |> Repo.update!()
  end

  # Participation
  # -------------
  def apply_participant(%SurveyTool{} = survey_tool, %User{} = user) do
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
    |> Repo.transaction()
  end

  def list_participants(%SurveyTool{} = survey_tool) do
    from(p in Participant,
      where: p.survey_tool_id == ^survey_tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_participations(%User{} = user) do
    from(s in SurveyTool,
      join: p in Participant,
      on: s.id == p.survey_tool_id,
      where: p.user_id == ^user.id
    )
    |> Repo.all()
  end
end
