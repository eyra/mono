defmodule Link.Authorization do
  @moduledoc """
  The authorization system for Link.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use GreenLight,
    repo: Link.Repo,
    roles: [:visitor, :member, :researcher, :owner, :participant],
    role_assignment_schema: Link.Authorization.RoleAssignment

  import Ecto.Query

  GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  grant_access(LinkWeb.Index, [:visitor, :member])
  grant_access(LinkWeb.Dashboard, [:member])
  grant_access(LinkWeb.User.Signin, [:visitor])
  grant_access(LinkWeb.User.Signup, [:visitor])
  grant_access(LinkWeb.User.ResetPassword, [:visitor])
  grant_access(LinkWeb.User.ResetPasswordToken, [:visitor])
  grant_access(LinkWeb.User.AwaitConfirmation, [:visitor])
  grant_access(LinkWeb.User.ConfirmToken, [:visitor])
  grant_access(LinkWeb.User.Profile, [:member])
  grant_access(LinkWeb.User.SecuritySettings, [:member])
  grant_access(LinkWeb.Study.New, [:researcher])
  grant_access(LinkWeb.Study.Edit, [:owner])
  grant_access(LinkWeb.Study.Public, [:visitor, :member])
  grant_access(LinkWeb.Study.Complete, [:member])
  grant_access(LinkWeb.FakeSurvey, [:member])

  grant_access(Link.Studies.Study, [:visitor, :member])
  grant_access(Link.SurveyTools.SurveyTool, [:owner, :participant])
  grant_access(Link.SurveyTools.SurveyToolTask, [:participant])

  grant_actions(LinkWeb.DashboardController, %{
    index: [:member]
  })

  grant_actions(LinkWeb.FakeSurveyController, %{
    index: [:visitor, :member]
  })

  grant_actions(LinkWeb.LanguageSwitchController, %{
    index: [:visitor, :member]
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

  def make_node(), do: %Link.Authorization.Node{}
  def make_node(nil), do: make_node()

  def make_node(parent_id) when is_integer(parent_id) do
    %Link.Authorization.Node{parent_id: parent_id}
  end

  def make_node(parent) do
    GreenLight.AuthorizationNode.id(parent) |> make_node
  end

  def create_node(parent \\ nil) do
    case make_node(parent) |> Link.Repo.insert() do
      {:ok, node} -> {:ok, node.id}
      error -> error
    end
  end

  defp parent_node_query(entity) do
    initial_query =
      Link.Authorization.Node |> where([n], n.id == ^GreenLight.AuthorizationNode.id(entity))

    recursion_query =
      Link.Authorization.Node
      |> join(:inner, [n], nt in "auth_node_parents", on: n.id == nt.parent_id)

    parents_query = initial_query |> union_all(^recursion_query)

    from("auth_node_parents")
    |> recursive_ctes(true)
    |> with_cte("auth_node_parents", as: ^parents_query)
    |> select([n], n.id)
  end

  def get_parent_nodes(node_id) do
    node_id |> parent_node_query |> Link.Repo.all()
  end

  def roles_intersect?(principal, node_id, roles) do
    nodes_query = node_id |> parent_node_query

    from(ra in Link.Authorization.RoleAssignment,
      where:
        ra.node_id in subquery(nodes_query) and ra.role in ^roles and
          ra.principal_id == ^GreenLight.Principal.id(principal)
    )
    |> Link.Repo.exists?()
  end

  defp has_required_roles_in_context?(principal, entity, permission) do
    roles_with_permission =
      permission_map() |> GreenLight.PermissionMap.roles(permission) |> MapSet.to_list()

    roles_intersect?(principal, entity, roles_with_permission)
  end

  def can_access?(principal, module) when is_atom(module) do
    permission = GreenLight.Permissions.access_permission(module)
    can?(principal, permission)
  end

  def can?(principal, entity, permission) when is_binary(permission) do
    can?(principal, permission) or
      has_required_roles_in_context?(principal, entity, permission)
  end

  def can_access?(principal, entity, module) when is_atom(module) do
    can?(principal, entity, GreenLight.Permissions.access_permission(module))
  end
end
