defmodule Systems.Assignment.Context do
  @moduledoc """
  The assignment context.
  """

  import Ecto.Query, warn: false
  import CoreWeb.Gettext

  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias CoreWeb.UI.Timestamp
  alias Core.Authorization
  alias Core.Accounts

  alias Frameworks.{
    Signal,
    Utility
  }

  alias Systems.{
    Assignment,
    Crew,
    Survey,
    Lab
  }

  @min_expiration_timeout 30

  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_crew!(%{id: crew_id}), do: get_by_crew!(crew_id)

  def get_by_crew!(crew_id) when is_number(crew_id) do
    from(a in Assignment.Model, where: a.crew_id == ^crew_id)
    |> Repo.all()
  end

  def get_by_assignable(assignable, preload \\ [])

  def get_by_assignable(%Assignment.ExperimentModel{id: id}, preload) do
    from(a in Assignment.Model,
      where: a.assignable_experiment_id == ^id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_experiment!(experiment, preload \\ [])

  def get_by_experiment!(%{id: experiment_id}, preload),
    do: get_by_experiment!(experiment_id, preload)

  def get_by_experiment!(experiment_id, preload) when is_number(experiment_id) do
    from(a in Assignment.Model,
      where: a.assignable_experiment_id == ^experiment_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_by_tool(%Survey.ToolModel{id: id}, preload) do
    query_by_tool(preload)
    |> where([assignment, experiment], experiment.survey_tool_id == ^id)
    |> Repo.one()
  end

  def get_by_tool(%Lab.ToolModel{id: id}, preload) do
    query_by_tool(preload)
    |> where([assignment, experiment], experiment.lab_tool_id == ^id)
    |> Repo.one()
  end

  defp query_by_tool(preload) do
    from(assignment in Assignment.Model,
      join: experiment in Assignment.ExperimentModel,
      on: assignment.assignable_experiment_id == experiment.id,
      preload: ^preload
    )
  end

  def list_user_ids(assignment_ids) when is_list(assignment_ids) do
    from(u in Accounts.User,
      join: m in Crew.MemberModel,
      on: m.user_id == u.id,
      join: a in Assignment.Model,
      on: a.crew_id == m.crew_id,
      where: a.id in ^assignment_ids,
      select: u.id
    )
    |> Repo.all()
  end

  def create(%{} = attrs, crew, experiment, auth_node) do
    assignable_field = assignable_field(experiment)

    %Assignment.Model{}
    |> Assignment.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(assignable_field, experiment)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def copy(
        %Assignment.Model{} = assignment,
        %Assignment.ExperimentModel{} = experiment,
        auth_node
      ) do
    # don't copy crew, just create a new one
    {:ok, crew} = Crew.Context.create(auth_node)

    %Assignment.Model{}
    |> Assignment.Model.changeset(Map.from_struct(assignment))
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:assignable_experiment, experiment)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def exclude(%Assignment.Model{} = assignment1, %Assignment.Model{} = assignment2) do
    Multi.new()
    |> Assignment.ExcludeModel.exclude(assignment1, assignment2)
    |> Assignment.ExcludeModel.exclude(assignment2, assignment1)
    |> Repo.transaction()
  end

  def include(%Assignment.Model{} = assignment1, %Assignment.Model{} = assignment2) do
    Multi.new()
    |> Assignment.ExcludeModel.include(assignment1, assignment2)
    |> Assignment.ExcludeModel.include(assignment2, assignment1)
    |> Repo.transaction()
  end

  def update_experiment(changeset) do
    with {:ok, %{experiment: experiment} = result} <-
           Multi.new()
           |> Multi.update(:experiment, changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:experiment_updated, experiment)
      {:ok, result}
    end
  end

  def create_experiment(%{} = attrs, tool, auth_node) do
    tool_field = Assignment.ExperimentModel.tool_field(tool)

    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:create, attrs)
    |> Ecto.Changeset.put_assoc(tool_field, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def copy_experiment(
        %Assignment.ExperimentModel{} = experiment,
        %Survey.ToolModel{} = tool,
        auth_node
      ) do
    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:copy, Map.from_struct(experiment))
    |> Ecto.Changeset.put_assoc(:survey_tool, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def copy_experiment(
        %Assignment.ExperimentModel{} = experiment,
        %Lab.ToolModel{} = tool,
        auth_node
      ) do
    %Assignment.ExperimentModel{}
    |> Assignment.ExperimentModel.changeset(:copy, Map.from_struct(experiment))
    |> Ecto.Changeset.put_assoc(:lab_tool, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def copy_tool(
        %Assignment.ExperimentModel{survey_tool: %{auth_node: tool_auth_node} = tool},
        experiment_auth_node
      ) do
    tool_auth_node = Authorization.copy(tool_auth_node, experiment_auth_node)
    Survey.Context.copy(tool, tool_auth_node)
  end

  def copy_tool(
        %Assignment.ExperimentModel{lab_tool: %{auth_node: tool_auth_node} = tool},
        experiment_auth_node
      ) do
    tool_auth_node = Authorization.copy(tool_auth_node, experiment_auth_node)
    Lab.Context.copy(tool, tool_auth_node)
  end

  def delete_tool(multi, %{survey_tool: tool}) when not is_nil(tool) do
    multi |> Utility.EctoHelper.delete(:survey_tool, tool)
  end

  def delete_tool(multi, %{lab_tool: tool}) when not is_nil(tool) do
    multi |> Utility.EctoHelper.delete(:lab_tool, tool)
  end

  def owner!(%Assignment.Model{} = assignment), do: parent_owner!(assignment)
  def owner!(%Assignment.ExperimentModel{} = experiment), do: parent_owner!(experiment)

  def assign_tester_role(tool, user) do
    %{crew: crew} = get_by_tool(tool, [:crew])

    if not Core.Authorization.user_has_role?(user, crew, :tester) do
      Core.Authorization.assign_role(user, crew, :tester)
    end
  end

  defp parent_owner!(entity) do
    case parent_owner(entity) do
      {:ok, user} -> user
      _ -> nil
    end
  end

  defp parent_owner(%{auth_node_id: _auth_node_id} = entity) do
    entity
    |> Authorization.top_entity()
    |> Authorization.first_user_with_role(:owner, [])
  end

  def expiration_timestamp(%{assignable_experiment: experiment}) do
    duration = Assignment.ExperimentModel.duration(experiment)
    timeout = max(@min_expiration_timeout, duration)

    Timestamp.naive_from_now(timeout)
  end

  def apply_member(id, user) when is_number(id) do
    apply_member(get!(id, [:crew]), user)
  end

  def apply_member(%{crew: crew} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      Crew.Context.get_member!(crew, user)
    else
      expire_at = expiration_timestamp(assignment)
      Crew.Context.apply_member!(crew, user, expire_at)
    end
  end

  def reset_member(%{crew: crew} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      expire_at = expiration_timestamp(assignment)

      Crew.Context.get_member!(crew, user)
      |> Crew.Context.reset_member(expire_at)
    else
      Logger.warn("Unable to reset, user #{user.id} is not a member on crew #{crew.id}")
    end
  end

  def cancel(%Assignment.Model{} = assignment, user) do
    crew = get_crew(assignment)
    Crew.Context.cancel(crew, user)
  end

  def cancel(id, user) do
    get!(id) |> cancel(user)
  end

  def lock_task(%{crew: crew} = _assignment, user) do
    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)
      Crew.Context.lock_task(task)
    else
      Logger.warn("Can not lock task for non member")
    end
  end

  def activate_task(crew_ref, user, force_apply_as_member? \\ false)

  def activate_task(%{} = tool, user_id, force_apply_as_member?) when is_integer(user_id) do
    if experiment = get_experiment_by_tool(tool) do
      %{crew: crew} = get_by_experiment!(experiment, [:crew])

      user = Accounts.get_user!(user_id)
      activate_task(crew, user, force_apply_as_member?)
    else
      nil
    end
  end

  def activate_task(
        %Assignment.Model{crew: crew},
        %Core.Accounts.User{} = user,
        force_apply_as_member?
      ) do
    activate_task(crew, user, force_apply_as_member?)
  end

  def activate_task(%Crew.Model{} = crew, %Core.Accounts.User{} = user, force_apply_as_member?) do
    member =
      if Crew.Context.member?(crew, user) do
        Crew.Context.get_member!(crew, user)
      else
        if force_apply_as_member? do
          Crew.Context.apply_member!(crew, user)
        else
          Logger.warn("Can not complete task for non member")
          nil
        end
      end

    _activate_task(crew, member)
  end

  defp _activate_task(%Crew.Model{} = _crew, nil), do: nil

  defp _activate_task(%Crew.Model{} = crew, %Crew.MemberModel{} = member) do
    Crew.Context.get_task(crew, member)
    |> Crew.Context.activate_task!()
  end

  @doc """
  How many new members can be added to the assignment?
  """
  def open_spot_count(%{crew: _crew} = assignment) do
    type = assignment_type(assignment)
    open_spot_count?(assignment, type)
  end

  @doc """
    Can this user apply for this assignment: is assignment open and is user not excluded?
  """
  def can_apply_as_member?(assignment, user) do
    if open?(assignment) do
      if excluded?(assignment, user) do
        {:error, :excluded}
      else
        {:ok}
      end
    else
      {:error, :closed}
    end
  end

  @doc """
    Is user excluded? from joining given assignment
  """
  def excluded?(%{id: to_id} = _assignment, %{id: user_id}) do
    from(assignment in Assignment.Model,
      join: exclude in Assignment.ExcludeModel,
      on: exclude.to_id == ^to_id,
      join: crew in Crew.Model,
      on: crew.id == assignment.crew_id,
      join: member in Crew.MemberModel,
      on: member.user_id == ^user_id,
      where: exclude.from_id == assignment.id and crew.id == member.crew_id,
      preload: [crew: [:members]]
    )
    |> Repo.exists?()
  end

  @doc """
  Is assignment open for new members?
  """
  def open?(%{crew: _crew} = assignment) do
    open_spot_count(assignment) > 0
  end

  def open?(_), do: true

  defp open_spot_count?(%{crew: crew, assignable_experiment: experiment}, :one_task) do
    target = Assignment.ExperimentModel.spot_count(experiment)
    all_non_expired_tasks = Crew.Context.count_tasks(crew, Crew.TaskStatus.values())

    max(0, target - all_non_expired_tasks)
  end

  defp assignment_type(_assignment) do
    # Some logic (eg: open?) is depending on the type of assignment.
    # Currently we only support the 1-task assignment: a member has one task todo.
    # Other types will be:
    #   N-tasks: a member can voluntaraly pick one or more tasks
    #   all-tasks: a member has a batch of tasks todo

    :one_task
  end

  def mark_expired_debug(%{assignable_experiment: %{duration: duration}} = assignment, force) do
    mark_expired_debug(assignment, duration, force)
  end

  def mark_expired_debug(%{crew_id: crew_id}, duration, force) do
    expiration_timeout = max(@min_expiration_timeout, duration)

    task_query =
      if force do
        pending_tasks_query(crew_id)
      else
        expired_pending_tasks_query(crew_id, expiration_timeout)
      end

    member_ids = from(t in task_query, select: t.member_id)
    member_query = from(m in Crew.MemberModel, where: m.id in subquery(member_ids))

    Multi.new()
    |> Multi.update_all(:members, member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end

  def pending_tasks_query(crew_id) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
          t.status == :pending and
          t.expired == false
    )
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout)
      when is_binary(expiration_timeout) do
    expired_pending_tasks_query(crew_id, String.to_integer(expiration_timeout))
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout) do
    expiration_timestamp =
      Timestamp.now()
      |> Timestamp.shift_minutes(expiration_timeout * -1)

    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
          t.status == :pending and
          t.expired == false and
          (t.started_at <= ^expiration_timestamp or
             (is_nil(t.started_at) and t.updated_at <= ^expiration_timestamp))
    )
  end

  # Crew
  def get_crew(%{crew_id: crew_id} = _assignment) do
    from(
      c in Crew.Model,
      where: c.id == ^crew_id
    )
    |> Repo.one()
  end

  # Assignable

  def ready?(%{assignable_experiment: experiment}) do
    ready?(experiment)
  end

  def ready?(%Assignment.ExperimentModel{} = experiment) do
    changeset =
      %Assignment.ExperimentModel{}
      |> Assignment.ExperimentModel.operational_changeset(Map.from_struct(experiment))

    changeset.valid? && tool_ready?(experiment)
  end

  def tool_ready?(%{survey_tool: tool}) when not is_nil(tool), do: Survey.Context.ready?(tool)
  def tool_ready?(%{lab_tool: tool}) when not is_nil(tool), do: Lab.Context.ready?(tool)

  defp assignable_field(%Assignment.ExperimentModel{}), do: :assignable_experiment

  # Experiment

  def get_experiment!(id, preload \\ []) do
    from(a in Assignment.ExperimentModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_experiment_by_tool(%{id: tool_id} = tool, preload \\ []) do
    tool_id_field = Assignment.ExperimentModel.tool_id_field(tool)
    where = [{tool_id_field, tool_id}]

    from(a in Assignment.ExperimentModel,
      where: ^where,
      preload: ^preload
    )
    |> Repo.one()
  end

  def attention_list_enabled?(%{assignable_experiment: %{survey_tool: tool}})
      when not is_nil(tool),
      do: true

  def attention_list_enabled?(%{assignable_experiment: %{lab_tool: tool}}) when not is_nil(tool),
    do: false

  def task_labels(%{assignable_experiment: %{lab_tool: tool}}) when not is_nil(tool) do
    %{
      pending: dgettext("link-lab", "pending.label"),
      participated: dgettext("link-lab", "participated.label")
    }
  end

  def task_labels(%{assignable_experiment: %{survey_tool: tool}}) when not is_nil(tool) do
    %{
      pending: dgettext("link-survey", "pending.label"),
      participated: dgettext("link-survey", "participated.label")
    }
  end

  def search_subject(tool, %Core.Accounts.User{} = user) do
    if experiment = get_experiment_by_tool(tool) do
      %{crew: crew} = get_by_experiment!(experiment, [:crew])
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)
      {member, task}
    else
      nil
    end
  end

  def search_subject(tool, public_id) do
    if experiment = get_experiment_by_tool(tool) do
      %{crew: crew} = get_by_experiment!(experiment, [:crew])
      member = Crew.Context.subject(crew, public_id)
      task = Crew.Context.get_task(crew, member)
      {member, task}
    else
      nil
    end
  end
end

defimpl Core.Persister, for: Systems.Assignment.ExperimentModel do
  def save(_model, changeset) do
    Systems.Assignment.Context.update_experiment(changeset)
  end
end
