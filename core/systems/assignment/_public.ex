defmodule Systems.Assignment.Public do
  @moduledoc """
  The assignment context.
  """
  use Core, :public
  import Ecto.Query, warn: false
  import Systems.Assignment.Queries

  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias CoreWeb.UI.Timestamp
  alias Systems.Account.User
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Concept
  alias Frameworks.Signal

  alias Systems.Assignment
  alias Systems.Account
  alias Systems.Content
  alias Systems.Consent
  alias Systems.Budget
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.Storage

  @min_expiration_timeout 30

  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get(id)
  end

  def get_by_content_page(%Content.PageModel{} = page, preload \\ []) do
    assignment_query(page)
    |> Repo.one()
    |> Repo.preload(preload)
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

  def list_by_participant(%Account.User{} = user, preload \\ []) do
    assignment_query(user, :participant)
    |> Repo.all()
    |> Repo.preload(preload)
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

  def get_by_workflow_item_id(workflow_item_id, preload \\ []) do
    %{workflow_id: workflow_id} = Workflow.Public.get_item!(String.to_integer(workflow_item_id))
    Assignment.Public.get_by(:workflow_id, workflow_id, preload)
  end

  def get_by_tool_ref(workflow, preload \\ [])

  def get_by_tool_ref(%Workflow.ToolRefModel{id: id}, preload), do: get_by_tool_ref(id, preload)

  def get_by_tool_ref(tool_ref_id, preload) do
    query_by_tool_ref(tool_ref_id, preload)
    |> Repo.one()
  end

  def get_by_tool(tool, preload \\ [])

  def get_by_tool(%{id: id} = tool, preload) do
    field_name = Workflow.ToolRefModel.tool_id_field(tool)

    query_by_tool(field_name, id, preload)
    |> Repo.one()
  end

  def query_by_tool(field_name, id, preload) do
    from(assignment in Assignment.Model,
      join: workflow in Workflow.Model,
      on: workflow.id == assignment.workflow_id,
      join: workflow_item in Workflow.ItemModel,
      on: workflow_item.workflow_id == workflow.id,
      join: tool_ref in Workflow.ToolRefModel,
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
      join: tool_ref in Workflow.ToolRefModel,
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

  def prepare_workflow(special, [_ | _] = items, auth_node) do
    %Workflow.Model{}
    |> Workflow.Model.changeset(%{special: special})
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Ecto.Changeset.put_assoc(:items, items)
  end

  def prepare_workflow(special, _, auth_node) do
    %Workflow.Model{}
    |> Workflow.Model.changeset(%{special: special})
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_workflow_items(tool_refs) when is_list(tool_refs) do
    tool_refs
    |> Enum.with_index()
    |> Enum.map(fn {tool_ref, index} -> prepare_workflow_item(tool_ref, %{position: index}) end)
  end

  def prepare_workflow_item(tool_ref, attrs \\ %{}) do
    %Workflow.ItemModel{}
    |> Workflow.ItemModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tool_ref, tool_ref)
  end

  def prepare_tool_ref(special, tool) do
    field_name = Workflow.ToolRefModel.tool_field(tool)
    Workflow.Public.prepare_tool_ref(special, field_name, tool)
  end

  def prepare_page_refs(_template, auth_node) do
    [
      prepare_page_ref(auth_node, :assignment_information)
    ]
  end

  def prepare_page_ref(auth_node, key) when is_atom(key) do
    page_body = Assignment.Private.page_body_default(key)
    page_auth_node = auth_module().prepare_node(auth_node)
    page = Content.Public.prepare_page(page_body, page_auth_node)

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

  def delete_storage_endpoint!(%{storage_endpoint: %Ecto.Association.NotLoaded{}} = assignment) do
    Repo.preload(assignment, :storage_endpoint, Storage.EndpointModel.preload_graph(:down))
    |> delete_storage_endpoint!()
  end

  def delete_storage_endpoint!(%{storage_endpoint: storage_endpoint} = assignment) do
    changeset =
      Assignment.Model.changeset(assignment, %{})
      |> Ecto.Changeset.put_assoc(:storage_endpoint, nil)

    storage_endpoint_special = Storage.EndpointModel.special(storage_endpoint)

    {:ok, %{assignment: assignment}} =
      Multi.new()
      |> EctoHelper.update_and_dispatch(changeset, :assignment)
      |> Multi.delete(:storage_endpoint_special, storage_endpoint_special)
      |> Repo.transaction()

    assignment
  end

  def delete_consent_agreement(assignment) do
    update_consent_agreement(assignment, nil)
  end

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

  def add_participant!(%Assignment.Model{crew: crew}, user) do
    if not Crew.Public.member?(crew, user) do
      {:ok, _} = Crew.Public.apply_member_with_role(crew, user, :participant)
    end
  end

  def participant_id(%Assignment.Model{crew: crew}, user) do
    case Crew.Public.get_member_unsafe(crew, user) do
      %{public_id: public_id} -> {:ok, public_id}
      _ -> :error
    end
  end

  def owner!(%Assignment.Model{} = assignment), do: parent_owner!(assignment)
  def owner!(%Workflow.Model{} = workflow), do: parent_owner!(workflow)
  def owner!(%Workflow.ItemModel{} = item), do: parent_owner!(item)

  def assign_tester_role(tool, user) do
    %{crew: crew} = get_by_tool(tool, [:crew])

    if not auth_module().user_has_role?(user, crew, :tester) do
      auth_module().assign_role(user, crew, :tester)
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
    |> auth_module().top_entity()
    |> auth_module().first_user_with_role(:owner, [])
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

  def count_participants(%{crew: crew} = _assignment) do
    Crew.Public.count_participants(crew)
  end

  def count_participants_finished(%{crew: crew} = _assignment) do
    Crew.Public.count_participants_finished(crew)
  end

  def tester?(%{crew: crew}, user_ref) do
    user_id = User.user_id(user_ref)
    auth_module().user_has_role?(user_id, crew, :tester)
  end

  def tester?(_, _), do: false

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

  def decline_member(%Assignment.Model{crew: crew}, user) do
    if member = Crew.Public.get_member(crew, user) do
      Multi.new()
      |> Crew.Public.expire_member(member)
      |> Signal.Public.multi_dispatch({:crew_member, :declined}, %{crew_member: member})
      |> Repo.transaction()
    else
      Logger.warning("Unable to decline member, probably expired already")
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

  def reset_member(%{crew: crew} = assignment, user, opts \\ []) do
    # get member regardless expired state
    if member = Crew.Public.get_member_unsafe(crew, user, [:crew]) do
      expire_at = expiration_timestamp(assignment)
      Crew.Public.reset_member!(member, expire_at, opts)
    else
      Logger.warning("Can not reset member for unknown user=#{user.id} in crew=#{crew.id}")
    end
  end

  def reject_task(
        %Assignment.Model{} = assignment,
        %Crew.TaskModel{} = task,
        rejection
      ) do
    [user] = auth_module().users_with_role(assignment, :owner)

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

  @doc """
    Lists the participants of the assignment.
    Returns a list of maps with the following keys:
    * `user_id`
    * `public_id`
    * `external_id`
    * `member_id`
  """
  def list_participants(%Assignment.Model{} = assignment) do
    participant_query(assignment)
    |> Repo.all()
  end

  def list_signatures(%Assignment.Model{consent_agreement_id: nil}) do
    []
  end

  def list_signatures(%Assignment.Model{} = assignment) do
    signature_query(assignment)
    |> Repo.all()
  end

  def list_tasks(%Assignment.Model{workflow: workflow}) do
    Workflow.Public.list_items(workflow)
  end

  def get_task(tool, identifier) do
    %{crew: crew} = Assignment.Public.get_by_tool(tool, [:crew])
    Crew.Public.get_task(crew, identifier)
  end

  def start_task(tool, identifier) do
    if task = get_task(tool, identifier) do
      Crew.Public.start_task(task)
    else
      Logger.warning("Can not start task")
    end
  end

  # def apply_member_and_complete_task(
  #       %Assignment.Model{crew: crew} = assignment,
  #       %User{} = user,
  #       identifier,
  #       reward_amount
  #     )
  #     when is_integer(reward_amount) do
  #   if not Crew.Public.member?(crew, user) do
  #     apply_member(assignment, user, identifier, reward_amount)
  #   end

  #   complete_task(crew, identifier)
  # end

  def complete_task(%Assignment.Model{crew: crew}, [_ | _] = identifier),
    do: complete_task(crew, identifier)

  def complete_task(%Crew.Model{} = crew, [_ | _] = identifier) do
    Crew.Public.get_task(crew, identifier)
    |> Crew.Public.complete_task!()
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
  def open_spot_count(%{crew: crew, info: %{subject_count: subject_count}}) do
    subject_count =
      if subject_count do
        subject_count
      else
        0
      end

    all_non_expired_members = Crew.Public.count_members(crew)
    max(0, subject_count - all_non_expired_members)
  end

  def mark_expired_debug(%{info: %{duration: duration}, crew: crew} = _assignment, force) do
    expiration_timeout = max(@min_expiration_timeout, duration)
    Crew.Public.mark_expired_debug(crew, expiration_timeout, force)
  end

  # Crew
  def get_crew(%{crew_id: crew_id} = _assignment) do
    from(
      c in Crew.Model,
      where: c.id == ^crew_id
    )
    |> Repo.one()
  end

  def get_member_by_task(%Crew.TaskModel{} = task, preload \\ []) do
    member_id =
      Assignment.Private.member_id(task)
      |> String.to_integer()

    from(
      m in Crew.MemberModel,
      where: m.id == ^member_id
    )
    |> Repo.one()
    |> Repo.preload(preload)
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
      {:ok, %{assignment: assignment}} ->
        {:ok, assignment}

      {:error, new_changeset} ->
        {:error, new_changeset}

      _ ->
        {:error, changeset}
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
