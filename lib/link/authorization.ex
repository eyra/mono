defmodule Link.Authorization do
  @moduledoc """
  The authorization system for Link.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use GreenLight,
    repo: Link.Repo,
    roles: [:visitor, :member, :researcher, :owner, :participant],
    role_assignment_schema: Link.Users.RoleAssignment

  alias GreenLight.Principal
  alias Link.Users
  import Ecto.Query

  GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  grant_access(LinkWeb.Study.New, [:researcher])
  grant_access(LinkWeb.Study.Show, [:owner])

  grant_access(Link.Studies.Study, [:visitor, :member])
  grant_access(Link.SurveyTools.SurveyTool, [:owner, :participant])
  grant_access(Link.SurveyTools.SurveyToolTask, [:participant])

  grant_actions(LinkWeb.DashboardController, %{
    index: [:member]
  })

  grant_actions(LinkWeb.FakeSurveyController, %{
    index: [:visitor, :member]
  })

  grant_actions(LinkWeb.SessionController, %{
    new: [:visitor]
  })

  grant_actions(LinkWeb.RegistrationController, %{
    new: [:visitor]
  })

  grant_actions(LinkWeb.LanguageSwitchController, %{
    index: [:visitor, :member]
  })

  grant_actions(LinkWeb.UserProfileController, %{
    edit: [:member],
    update: [:member]
  })

  grant_actions(LinkWeb.StudyController, %{
    index: [:visitor, :member],
    show: [:visitor, :member],
    new: [:researcher],
    create: [:researcher],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(LinkWeb.Studies.PermissionsController, %{
    show: [:owner],
    change: [:owner],
    create: [:owner]
  })

  grant_actions(LinkWeb.ParticipantController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:member],
    create: [:member],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(LinkWeb.SurveyToolController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:owner],
    create: [:owner],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(LinkWeb.SurveyToolTaskController, %{
    start: [:participant],
    complete: [:participant],
    setup_tasks: [:owner]
  })

  grant_actions(LinkWeb.PageController, %{
    index: [:visitor, :member]
  })

  def principal(%Plug.Conn{} = conn) do
    Pow.Plug.current_user(conn)
    |> principal()
  end

  def principal(user) when is_nil(user) do
    %Principal{id: nil, roles: MapSet.new([:visitor])}
  end

  def principal(%Link.Users.User{} = user) do
    roles =
      [:member | if(Users.get_profile(user).researcher, do: [:researcher], else: [])]
      |> MapSet.new()

    %Principal{id: user.id, roles: roles}
  end

  def assign_role!(%Link.Users.User{} = user, entity, role) do
    user |> principal() |> assign_role!(entity, role)
  end

  def remove_role!(%Link.Users.User{} = user, entity, role) do
    user |> principal() |> remove_role!(entity, role)
  end

  def list_roles(%Link.Users.User{} = user, entity) do
    user |> principal() |> list_roles(entity)
  end

  def can?(%Plug.Conn{} = conn, entity, module, action) do
    conn |> principal() |> can?(entity, module, action)
  end

  def can?(%Link.Users.User{} = user, entity, module, action) do
    user |> principal() |> can?(entity, module, action)
  end

  def map_to_auth_entity(nil) do
    nil
  end

  def map_to_auth_entity(%Link.SurveyTools.SurveyToolTask{} = task) do
    {Atom.to_string(Link.SurveyTools.SurveyToolTask),
     :erlang.phash(
       {task.survey_tool_id, task.user_id},
       :math.pow(2, 32) |> floor()
     )}
  end

  def map_to_auth_entity(entity) do
    {Atom.to_string(entity.__struct__), entity.id}
  end

  def make_node(parent_id \\ nil) do
    %Link.Authorization.Node{parent_id: parent_id}
  end

  def create_node(parent_id \\ nil) do
    case make_node(parent_id) |> Link.Repo.insert() do
      {:ok, node} -> {:ok, node.id}
      error -> error
    end
  end

  defp parent_node_query(node_id) do
    initial_query = Link.Authorization.Node |> where([n], n.id == ^node_id)

    recursion_query =
      Link.Authorization.Node
      |> join(:inner, [n], nt in "auth_node_parents", on: n.id == nt.parent_id)

    parents_query = initial_query |> union_all(^recursion_query)

    query =
      from("auth_node_parents")
      |> recursive_ctes(true)
      |> with_cte("auth_node_parents", as: ^parents_query)
      |> select([n], n.id)
  end

  def get_parent_nodes(node_id) do
    node_id |> parent_node_query |> Link.Repo.all()
  end

  def assign_role(principal, node_id, role) do
    %Link.Authorization.RoleAssignment{principal_id: principal, node_id: node_id, role: role}
    |> Link.Repo.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  def roles_intersect?(principal, node_id, roles) do
    nodes_query = node_id |> parent_node_query

    from(ra in Link.Authorization.RoleAssignment,
      where: ra.node_id in subquery(nodes_query) and ra.role in ^roles
    )
    |> Link.Repo.exists?()
  end

  def can_access?(%Principal{} = principal, module) when is_atom(module) do
    permission = GreenLight.Permissions.access_permission(module)
    roles = principal.roles
    GreenLight.PermissionMap.allowed?(permission_map(), permission, roles)
  end

  def can_access?(user, module) when is_atom(module) do
    principal(user) |> can_access?(module)
  end

  def can_access?(%Principal{} = principal, node_id, permission)
      when is_integer(node_id) and is_binary(permission) do
    roles = principal.roles

    unless GreenLight.PermissionMap.allowed?(permission_map(), permission, roles) do
      roles_with_permission =
        permission_map() |> GreenLight.PermissionMap.roles(permission) |> MapSet.to_list()

      roles_intersect?(principal.id, node_id, roles_with_permission)
    end
  end

  def can_access?(%Principal{} = principal, node_id, module)
      when is_integer(node_id) and is_atom(module) do
    can_access?(principal, node_id, GreenLight.Permissions.access_permission(module))
  end

  def can_access?(%Link.Users.User{} = user, node_id, module) when is_integer(node_id) do
    can_access?(principal(user), node_id, module)
  end

  def can_access?(nil, node_id, module) when is_integer(node_id) do
    can_access?(principal(nil), module)
  end

  def can_access?(user, %Link.Studies.Study{} = study, module) do
    can_access?(user, study.auth_node_id, module)
  end
end
