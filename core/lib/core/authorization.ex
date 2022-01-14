defmodule Core.Authorization do
  @moduledoc """
  The authorization system for Core.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use Frameworks.GreenLight.Context,
    repo: Core.Repo,
    roles: [:visitor, :member, :student, :researcher, :owner, :participant, :coordinator, :admin],
    role_assignment_schema: Core.Authorization.RoleAssignment

  use Core.BundleOverrides

  alias Frameworks.GreenLight

  import Ecto.Query
  alias Core.Repo

  Frameworks.GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  Core.BundleOverrides.grants()

  grant_access(Systems.Campaign.Model, [:visitor, :member])
  grant_access(Systems.Survey.ToolModel, [:owner, :coordinator, :participant])
  grant_access(Systems.Lab.ToolModel, [:owner, :coordinator, :participant])
  grant_access(Systems.DataDonation.ToolModel, [:owner, :coordinator, :participant])

  grant_access(Systems.Admin.LoginPage, [:visitor, :member])
  grant_access(Systems.Admin.PermissionsPage, [:admin])
  grant_access(Systems.Support.OverviewPage, [:admin])
  grant_access(Systems.Support.TicketPage, [:admin])
  grant_access(Systems.Support.HelpdeskPage, [:member])
  grant_access(Systems.Notification.OverviewPage, [:member])
  grant_access(Systems.NextAction.OverviewPage, [:member])
  grant_access(Systems.Campaign.OverviewPage, [:researcher])
  grant_access(Systems.Campaign.ContentPage, [:owner])
  grant_access(Systems.Assignment.LandingPage, [:participant])
  grant_access(Systems.Assignment.CallbackPage, [:participant])
  grant_access(Systems.Lab.PublicPage, [:member])
  grant_access(Systems.Promotion.LandingPage, [:visitor, :member, :owner])
  grant_access(Systems.Pool.OverviewPage, [:researcher])
  grant_access(Systems.Pool.SubmissionPage, [:researcher])
  grant_access(Systems.Test.Page, [:visitor, :member])
  grant_access(Systems.DataDonation.Content, [:owner, :coordinator])
  grant_access(Systems.DataDonation.Uploader, [:member])

  grant_access(CoreWeb.Dashboard, [:researcher])
  grant_access(CoreWeb.User.Signin, [:visitor])
  grant_access(CoreWeb.User.Signup, [:visitor])
  grant_access(CoreWeb.User.ResetPassword, [:visitor])
  grant_access(CoreWeb.User.ResetPasswordToken, [:visitor])
  grant_access(CoreWeb.User.AwaitConfirmation, [:visitor])
  grant_access(CoreWeb.User.ConfirmToken, [:visitor])
  grant_access(CoreWeb.User.Profile, [:member])
  grant_access(CoreWeb.User.Settings, [:member])
  grant_access(CoreWeb.User.SecuritySettings, [:member])
  grant_access(CoreWeb.FakeSurvey, [:member])

  grant_actions(CoreWeb.FakeSurveyController, %{
    index: [:visitor, :member]
  })

  grant_actions(CoreWeb.LanguageSwitchController, %{
    index: [:visitor, :member]
  })

  def get_node!(id), do: Repo.get!(Core.Authorization.Node, id)

  def make_node(), do: %Core.Authorization.Node{}

  def make_node(%Core.Authorization.Node{} = parent) do
    %Core.Authorization.Node{parent_id: parent.id}
  end

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

  def create_node!(parent \\ nil) do
    case make_node(parent) |> Core.Repo.insert() do
      {:ok, node} -> node
      error -> error
    end
  end

  def copy(%Core.Authorization.Node{role_assignments: role_assignments})
      when is_list(role_assignments) do
    auth_node = create_node!()

    role_assignments
    |> Enum.each(&copy_role(&1, auth_node))

    auth_node
  end

  def copy(_auth_node, %Core.Authorization.Node{} = parent) do
    create_node!(parent)
  end

  def copy_role(%Core.Authorization.RoleAssignment{} = role, node) do
    %Core.Authorization.RoleAssignment{}
    |> Core.Authorization.RoleAssignment.changeset(Map.from_struct(role))
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Repo.insert!()
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

  def users_with_role(_, _, preload \\ [])

  def users_with_role(node_id, role, preload) when is_number(node_id) do
    principal_ids = Core.Authorization.query_principal_ids(node_id: node_id, role: role)

    Ecto.Query.from(u in Core.Accounts.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload
    )
    |> Core.Repo.all()
  end

  def users_with_role(entity, role, preload) do
    principal_ids = Core.Authorization.query_principal_ids(role: role, entity: entity)

    Ecto.Query.from(u in Core.Accounts.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload
    )
    |> Core.Repo.all()
  end

  def user_has_role?(user, entity, role) do
    users_with_role(entity, role)
    |> Enum.any?(&(&1.id == user.id))
  end
end
