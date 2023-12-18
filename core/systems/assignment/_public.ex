defmodule Systems.Assignment.Public do
  @moduledoc """
  The assignment context.
  """
  import Ecto.Query, warn: false

  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias CoreWeb.UI.Timestamp
  alias Core.Authorization
  alias Core.Accounts.User
  alias Frameworks.Concept
  alias Frameworks.Signal

  alias Systems.{
    Project,
    Assignment,
    Content,
    Consent,
    Budget,
    Workflow,
    Crew,
    Storage
  }

  @min_expiration_timeout 30

  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_workflow!(id, preload \\ []) do
    from(a in Workflow.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def list_by_crew(crew, preload \\ [])

  def list_by_crew(%{id: crew_id}, preload), do: list_by_crew(crew_id, preload)

  def list_by_crew(crew_id, preload) when is_number(crew_id) do
    from(a in Assignment.Model, where: a.crew_id == ^crew_id, preload: ^preload)
    |> Repo.all()
  end

  def get_by(association, preload \\ [])
  def get_by(%Assignment.PageRefModel{assignment_id: id}, preload), do: get!(id, preload)

  def get_by(%Assignment.InfoModel{id: id}, preload), do: get_by(:info_id, id, preload)

  def get_by(%Storage.EndpointModel{id: id}, preload),
    do: get_by(:storage_endpoint_id, id, preload)

  def get_by(%Consent.AgreementModel{id: id}, preload),
    do: get_by(:consent_agreement_id, id, preload)

  def get_by(%Workflow.Model{id: id}, preload), do: get_by(:workflow_id, id, preload)

  def get_by(%Crew.Model{id: id}, preload), do: get_by(:crew_id, id, preload)

  def get_by(field_name, id, preload) when is_atom(field_name) do
    Repo.get_by(Assignment.Model, [{field_name, id}])
    |> Repo.preload(preload)
  end

  def get_by_tool_ref(workflow, preload \\ [])

  def get_by_tool_ref(%Project.ToolRefModel{id: id}, preload), do: get_by_tool_ref(id, preload)

  def get_by_tool_ref(tool_ref_id, preload) do
    query_by_tool_ref(tool_ref_id, preload)
    |> Repo.one()
  end

  def get_by_tool(tool, preload \\ [])

  def get_by_tool(%{id: id} = tool, preload) do
    field_name = Project.ToolRefModel.tool_id_field(tool)

    query_by_tool(field_name, id, preload)
    |> Repo.one()
  end

  def query_by_tool(field_name, id, preload) do
    from(assignment in Assignment.Model,
      join: workflow in Workflow.Model,
      on: workflow.id == assignment.workflow_id,
      join: workflow_item in Workflow.ItemModel,
      on: workflow_item.workflow_id == workflow.id,
      join: tool_ref in Project.ToolRefModel,
      on: tool_ref.id == workflow_item.tool_ref_id,
      where: field(tool_ref, ^field_name) == ^id,
      preload: ^preload
    )
  end

  def query_by_tool_ref(tool_ref_id, preload) do
    from(assignment in Assignment.Model,
      join: workflow in Workflow.Model,
      on: workflow.id == assignment.workflow_id,
      join: workflow_item in Workflow.ItemModel,
      on: workflow_item.workflow_id == workflow.id,
      join: tool_ref in Project.ToolRefModel,
      on: tool_ref.id == ^tool_ref_id,
      preload: ^preload
    )
  end

  def list_user_ids(assignment_ids) when is_list(assignment_ids) do
    from(u in User,
      join: m in Crew.MemberModel,
      on: m.user_id == u.id,
      join: a in Assignment.Model,
      on: a.crew_id == m.crew_id,
      where: a.id in ^assignment_ids,
      select: u.id
    )
    |> Repo.all()
  end

  def prepare(%{} = attrs, crew, info, page_refs, workflow, budget, consent_agreement, auth_node) do
    %Assignment.Model{}
    |> Assignment.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:info, info)
    |> Ecto.Changeset.put_assoc(:page_refs, page_refs)
    |> Ecto.Changeset.put_assoc(:workflow, workflow)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:budget, budget)
    |> Ecto.Changeset.put_assoc(:consent_agreement, consent_agreement)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_info(%{} = attrs) do
    %Assignment.InfoModel{}
    |> Assignment.InfoModel.changeset(:create, attrs)
  end

  def prepare_workflow(special, items, type \\ :single_task) do
    %Workflow.Model{}
    |> Workflow.Model.changeset(%{type: type, special: special})
    |> Ecto.Changeset.put_assoc(:items, items)
  end

  def prepare_workflow_item(tool_ref) do
    %Workflow.ItemModel{}
    |> Workflow.ItemModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tool_ref, tool_ref)
  end

  def prepare_page_refs(_template, auth_node) do
    [
      prepare_page_ref(auth_node, :assignment_intro)
    ]
  end

  def prepare_page_ref(auth_node, key) when is_atom(key) do
    page_title = Assignment.Private.page_title_default(key)
    page_body = Assignment.Private.page_body_default(key)
    page_auth_node = Authorization.prepare_node(auth_node)
    page = Content.Public.prepare_page(page_title, page_body, page_auth_node)

    %Assignment.PageRefModel{}
    |> Assignment.PageRefModel.changeset(%{key: key})
    |> Ecto.Changeset.put_assoc(:page, page)
  end

  def create_page_ref(%Assignment.Model{auth_node: auth_node} = assignment, key) do
    page_ref =
      prepare_page_ref(auth_node, key)
      |> Ecto.Changeset.put_assoc(:assignment, assignment)

    Multi.new()
    |> Multi.insert(:assignment_page_ref, page_ref)
    |> Signal.Public.multi_dispatch({:assignment_page_ref, :inserted})
    |> Repo.transaction()
  end

  def delete_page_ref(
        %Assignment.PageRefModel{assignment_id: assignment_id, page_id: page_id} = page_ref
      ) do
    page_refs =
      from(pr in Assignment.PageRefModel,
        where: pr.assignment_id == ^assignment_id,
        where: pr.page_id == ^page_id
      )

    Multi.new()
    |> Multi.delete_all(:assignment_page_refs, page_refs)
    |> Signal.Public.multi_dispatch({:assignment_page_ref, :deleted}, %{
      assignment_page_ref: page_ref
    })
    |> Repo.transaction()
  end

  def delete_storage_endpoint!(%{storage_endpoint_id: nil} = assignment) do
    assignment
  end

  def delete_storage_endpoint!(assignment) do
    changeset =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:storage_endpoint, nil)

    {:ok, assignment} = Core.Persister.save(changeset.data, changeset)

    assignment
  end

  def create_storage_endpoint!(%{storage_endpoint_id: nil} = assignment) do
    storage_endpoint =
      %Storage.EndpointModel{}
      |> Storage.EndpointModel.changeset(%{})

    {:ok, assignment} =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:storage_endpoint, storage_endpoint)
      |> Repo.update()

    assignment
    |> Repo.preload(Assignment.Model.preload_graph(:down))
  end

  def create_storage_endpoint!(assignment), do: assignment

  def copy(
        %Assignment.Model{} = assignment,
        %Assignment.InfoModel{} = info,
        %Workflow.Model{} = workflow,
        %Budget.Model{} = budget,
        auth_node
      ) do
    # don't copy crew, just create a new one
    crew = Crew.Public.prepare(auth_node)

    %Assignment.Model{}
    |> Assignment.Model.changeset(Map.from_struct(assignment))
    |> Ecto.Changeset.put_assoc(:info, info)
    |> Ecto.Changeset.put_assoc(:workflow, workflow)
    |> Ecto.Changeset.put_assoc(:budget, budget)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def copy_info(%Assignment.InfoModel{} = info) do
    %Assignment.InfoModel{}
    |> Assignment.InfoModel.changeset(:copy, Map.from_struct(info))
    |> Repo.insert!()
  end

  def copy_workflow(%Workflow.Model{} = workflow) do
    %Workflow.Model{}
    |> Workflow.Model.changeset(Map.from_struct(workflow))
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

  def update(assignment, %{} = attrs) do
    changeset = Assignment.Model.changeset(assignment, attrs)
    Core.Persister.save(assignment, changeset)
  end

  def update!(assignment, %{} = attrs) do
    case __MODULE__.update(assignment, attrs) do
      {:ok, assignment} -> assignment
      _ -> nil
    end
  end

  def update_budget(assignment, budget) do
    changeset =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:budget, budget)

    Core.Persister.save(assignment, changeset)
  end

  def update_consent_agreement(assignment, consent_agreement) do
    changeset =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:consent_agreement, consent_agreement)

    Core.Persister.save(assignment, changeset)
  end

  def update_storage_endpoint(assignment, storage_endpoint) do
    changeset =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:storage_endpoint, storage_endpoint)

    Core.Persister.save(assignment, changeset)
  end

  def is_owner?(assignment, user) do
    Core.Authorization.user_has_role?(user, assignment, :owner)
  end

  def add_owner!(assignment, user) do
    :ok = Core.Authorization.assign_role(user, assignment, :owner)
  end

  def owner!(%Assignment.Model{} = assignment), do: parent_owner!(assignment)
  def owner!(%Workflow.Model{} = workflow), do: parent_owner!(workflow)
  def owner!(%Workflow.ItemModel{} = item), do: parent_owner!(item)

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

  def expiration_timestamp(%{info: info}) do
    duration = Assignment.InfoModel.duration(info)
    timeout = max(@min_expiration_timeout, duration)

    Timestamp.naive_from_now(timeout)
  end

  def status(%{crew: crew}, user) do
    statuses =
      Crew.Public.list_tasks_for_user(crew, user)
      |> Enum.map(& &1.status)

    cond do
      Enum.member?(statuses, :rejected) -> :rejected
      Enum.member?(statuses, :pending) -> :pending
      Enum.member?(statuses, :completed) -> :completed
      true -> :accepted
    end
  end

  def timestamp(%{crew: crew}, user) do
    crew
    |> Crew.Public.list_tasks_for_user(user)
    |> List.first()
    |> timestamp()
  end

  def timestamp(%{updated_at: updated_at}), do: updated_at
  def timestamp(_), do: nil

  def member?(%{crew: crew}, user) do
    Crew.Public.member?(crew, user)
  end

  def apply_member(id, user, identifier, reward_amount) when is_number(id) do
    get!(id, [:crew])
    |> apply_member(user, identifier, reward_amount)
  end

  def apply_member(%{crew: crew} = assignment, user, identifier, reward_amount) do
    if Crew.Public.member?(crew, user) do
      Crew.Public.get_member(crew, user)
    else
      expire_at = expiration_timestamp(assignment)

      Multi.new()
      |> Multi.run(:reward, fn _, _ ->
        run_create_reward(assignment, user, reward_amount)
      end)
      |> Multi.run(:member, fn _, _ ->
        run_apply_member(crew, user, identifier, expire_at)
      end)
      |> Repo.transaction()
    end
  end

  defp run_create_reward(%Assignment.Model{budget: budget} = assignment, %User{} = user, amount) do
    idempotence_key = idempotence_key(assignment, user)

    case Budget.Public.create_reward(budget, amount, user, idempotence_key) do
      {:ok, %{reward: reward}} -> {:ok, reward}
      {:error, error} -> {:error, error}
    end
  end

  def run_apply_member(%Crew.Model{} = crew, user, identifier, expire_at) do
    case Crew.Public.apply_member(crew, user, identifier, expire_at) do
      {:ok, %{member: member}} -> {:ok, member}
      {:error, error} -> {:error, error}
    end
  end

  def reset_member(%{crew: crew} = assignment, user) do
    if Crew.Public.member?(crew, user) do
      expire_at = expiration_timestamp(assignment)

      Crew.Public.get_member(crew, user)
      |> Crew.Public.reset_member(expire_at)
    else
      Logger.warn("Unable to reset, user #{user.id} is not a member on crew #{crew.id}")
    end
  end

  def reject_task(
        %Assignment.Model{} = assignment,
        %Crew.TaskModel{} = task,
        rejection
      ) do
    [user] = Authorization.users_with_role(assignment, :owner)

    Multi.new()
    |> Crew.Public.reject_task(task, rejection)
    |> rollback_deposit(assignment, user)
    |> Repo.transaction()
  end

  def cancel(%Assignment.Model{crew: crew} = assignment, user) do
    Multi.new()
    |> Crew.Public.cancel(crew, user)
    |> rollback_deposit(assignment, user)
    |> Repo.transaction()
  end

  def cancel(id, user) do
    get!(id) |> cancel(user)
  end

  def get_task(tool, identifier) do
    %{crew: crew} = Assignment.Public.get_by_tool(tool, [:crew])
    Crew.Public.get_task(crew, identifier)
  end

  def lock_task(tool, identifier) do
    if task = get_task(tool, identifier) do
      Crew.Public.lock_task(task)
    else
      Logger.warn("Can not lock task")
    end
  end

  def apply_member_and_activate_task(
        %Assignment.Model{crew: crew} = assignment,
        %User{} = user,
        [_ | _] = identifier,
        reward_amount
      )
      when is_integer(reward_amount) do
    if not Crew.Public.member?(crew, user) do
      apply_member(assignment, user, identifier, reward_amount)
    end

    activate_task(crew, identifier)
  end

  def activate_task(%Assignment.Model{crew: crew}, [_ | _] = identifier),
    do: activate_task(crew, identifier)

  def activate_task(%Crew.Model{} = crew, [_ | _] = identifier) do
    Crew.Public.get_task(crew, identifier)
    |> Crew.Public.activate_task!()
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
      where: exclude.from_id == assignment.id,
      where: crew.id == member.crew_id,
      where: member.expired == false,
      preload: [crew: [:members]]
    )
    |> Repo.exists?()
  end

  def attention_list_enabled?(%{workflow: workflow}) do
    [tool] = Workflow.Model.flatten(workflow)
    Concept.ToolModel.attention_list_enabled?(tool)
  end

  def task_labels(%{workflow: workflow}) do
    [tool] = Workflow.Model.flatten(workflow)
    Concept.ToolModel.task_labels(tool)
  end

  @doc """
  Is assignment open for new members?
  """
  def has_open_spots?(%{crew: _crew} = assignment) do
    open_spot_count(assignment) > 0
  end

  def has_open_spots?(_), do: false

  @doc """
  How many new members can be added to the assignment?
  """
  def open_spot_count(%{crew: _crew} = assignment) do
    type = assignment_type(assignment)
    open_spot_count(assignment, type)
  end

  defp open_spot_count(%{crew: crew, info: %{subject_count: subject_count}}, :single_task) do
    all_non_expired_tasks = Crew.Public.count_tasks(crew, Crew.TaskStatus.values())
    max(0, subject_count - all_non_expired_tasks)
  end

  defp assignment_type(%{workflow: %{type: type}}), do: type

  def mark_expired_debug(%{info: %{duration: duration}} = assignment, force) do
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

    task_ids = from(t in task_query, select: t.id)
    member_query = Crew.Public.member_query(task_ids)

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

  def ready?(%{workflow: workflow}) do
    Workflow.Model.ready?(workflow)
  end

  def search_subject(%Assignment.Model{crew: crew}, %User{} = user) do
    member = Crew.Public.get_member(crew, user)
    tasks = Crew.Public.list_tasks_for_user(crew, member.user_id)
    {member, tasks}
  end

  def search_subject(%Assignment.Model{crew: crew}, public_id) do
    member = Crew.Public.subject(crew, public_id)
    tasks = Crew.Public.list_tasks_for_user(crew, member.user_id)
    {member, tasks}
  end

  def search_subject(%{} = tool, user) do
    search_subject(get_by_tool(tool, [:crew]), user)
  end

  def search_subject(nil, _), do: nil

  def expired_user_assignments(%NaiveDateTime{} = from) do
    from(a in Assignment.Model,
      inner_join: m in Crew.MemberModel,
      on: m.crew_id == a.crew_id,
      where: m.expired == true,
      where: m.expire_at >= ^from,
      select: {m.user_id, a.id}
    )
    |> Repo.all()
  end

  def rollback_expired_deposits() do
    one_day = 60 * 24
    from_one_day_ago = Timestamp.naive_from_now(-one_day)
    rollback_expired_deposits(from_one_day_ago)
  end

  def rollback_expired_deposits(%NaiveDateTime{} = from) do
    Multi.new()
    |> Multi.run(:rollback, fn _, _ ->
      expired_user_assignments(from)
      |> Enum.map(fn {user_id, assignment_id} ->
        idempotence_key(assignment_id, user_id)
      end)
      |> Enum.filter(&Budget.Public.reward_has_outstanding_deposit?(&1))
      |> Enum.each(&Budget.Public.rollback_deposit(&1))

      {:ok, true}
    end)
    |> Repo.transaction()
  end

  def rollback_deposit(%Multi{} = multi, %Assignment.Model{} = assignment, %User{} = user) do
    idempotence_key = idempotence_key(assignment, user)

    multi
    |> Budget.Public.rollback_deposit(idempotence_key)
  end

  def idempotence_key(%Assignment.Model{id: assignment_id}, %User{id: user_id}) do
    idempotence_key(assignment_id, user_id)
  end

  def idempotence_key(assignment_id, user_id)
      when is_integer(assignment_id) and is_integer(user_id) do
    "assignment=#{assignment_id},user=#{user_id}"
  end

  def payout_participant(%Assignment.Model{id: assignment_id}, %User{id: user_id}) do
    idempotence_key = idempotence_key(assignment_id, user_id)
    Budget.Public.payout_reward(idempotence_key)
  end

  def rewarded_amount(%Assignment.Model{id: assignment_id}, %User{id: user_id}) do
    idempotence_key = idempotence_key(assignment_id, user_id)
    Budget.Public.rewarded_amount(idempotence_key)
  end
end

defimpl Core.Persister, for: Systems.Assignment.Model do
  def save(_assignment, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :assignment) do
      {:ok, %{assignment: assignment}} -> {:ok, assignment}
      _ -> {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Systems.Assignment.InfoModel do
  def save(_info, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :assignment_info) do
      {:ok, %{assignment_info: assignment_info}} -> {:ok, assignment_info}
      _ -> {:error, changeset}
    end
  end
end
