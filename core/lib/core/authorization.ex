defmodule Core.Authorization do
  @moduledoc """
  The authorization system for Core.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use GreenLight,
    repo: Core.Repo,
    roles: [:visitor, :member, :researcher, :owner, :participant],
    role_assignment_schema: Core.Authorization.RoleAssignment

  use Core.BundleOverrides

  import Ecto.Query

  GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  Core.BundleOverrides.grants()

  grant_access(CoreWeb.Index, [:visitor, :member])
  grant_access(CoreWeb.Dashboard, [:member])
  grant_access(CoreWeb.Notifications, [:member])
  grant_access(CoreWeb.User.Signin, [:visitor])
  grant_access(CoreWeb.User.Signup, [:visitor])
  grant_access(CoreWeb.User.ResetPassword, [:visitor])
  grant_access(CoreWeb.User.ResetPasswordToken, [:visitor])
  grant_access(CoreWeb.User.AwaitConfirmation, [:visitor])
  grant_access(CoreWeb.User.ConfirmToken, [:visitor])
  grant_access(CoreWeb.User.Profile, [:member])
  grant_access(CoreWeb.User.SecuritySettings, [:member])
  grant_access(CoreWeb.Study.New, [:researcher])
  grant_access(CoreWeb.Study.Edit, [:owner])
  grant_access(CoreWeb.Study.Public, [:visitor, :member])
  grant_access(CoreWeb.Study.Complete, [:member])
  grant_access(CoreWeb.FakeSurvey, [:member])
  grant_access(CoreWeb.DataUploader.Uploader, [:visitor, :member])

  grant_access(Core.Studies.Study, [:visitor, :member])
  grant_access(Core.SurveyTools.SurveyTool, [:owner, :participant])
  grant_access(Core.SurveyTools.SurveyToolTask, [:participant])

  grant_actions(CoreWeb.DashboardController, %{
    index: [:member]
  })

  grant_actions(CoreWeb.FakeSurveyController, %{
    index: [:visitor, :member]
  })

  grant_actions(CoreWeb.LanguageSwitchController, %{
    index: [:visitor, :member]
  })

  grant_actions(CoreWeb.Studies.PermissionsController, %{
    show: [:owner],
    change: [:owner],
    create: [:owner]
  })

  grant_actions(CoreWeb.ParticipantController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:member],
    create: [:member],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(CoreWeb.SurveyToolController, %{
    index: [:owner],
    show: [:owner, :participant],
    new: [:owner],
    create: [:owner],
    edit: [:owner],
    update: [:owner],
    delete: [:owner]
  })

  grant_actions(CoreWeb.SurveyToolTaskController, %{
    start: [:participant],
    complete: [:participant],
    setup_tasks: [:owner]
  })

  grant_actions(CoreWeb.PageController, %{
    index: [:visitor, :member]
  })

  def make_node(), do: %Core.Authorization.Node{}
  def make_node(nil), do: make_node()

  def make_node(parent_id) when is_integer(parent_id) do
    %Core.Authorization.Node{parent_id: parent_id}
  end

  def make_node(parent) do
    GreenLight.AuthorizationNode.id(parent) |> make_node
  end

  def create_node(parent \\ nil) do
    case make_node(parent) |> Core.Repo.insert() do
      {:ok, node} -> {:ok, node.id}
      error -> error
    end
  end

  defp parent_node_query(entity) do
    initial_query =
      Core.Authorization.Node |> where([n], n.id == ^GreenLight.AuthorizationNode.id(entity))

    recursion_query =
      Core.Authorization.Node
      |> join(:inner, [n], nt in "auth_node_parents", on: n.id == nt.parent_id)

    parents_query = initial_query |> union_all(^recursion_query)

    from("auth_node_parents")
    |> recursive_ctes(true)
    |> with_cte("auth_node_parents", as: ^parents_query)
    |> select([n], n.id)
  end

  def get_parent_nodes(node_id) do
    node_id |> parent_node_query |> Core.Repo.all()
  end

  def roles_intersect?(principal, node_id, roles) do
    nodes_query = node_id |> parent_node_query

    from(ra in Core.Authorization.RoleAssignment,
      where:
        ra.node_id in subquery(nodes_query) and ra.role in ^roles and
          ra.principal_id == ^GreenLight.Principal.id(principal)
    )
    |> Core.Repo.exists?()
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

  def users_with_role(entity, role) do
    principal_ids = Core.Authorization.query_principal_ids(role: role, entity: entity)

    Ecto.Query.from(u in Core.Accounts.User,
      where: u.id in subquery(principal_ids)
    )
    |> Core.Repo.all()
  end
end
