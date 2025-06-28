defmodule Core.Authorization do
  @moduledoc """
  The authorization system for Core.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use Frameworks.GreenLight.Public,
    repo: Core.Repo,
    roles: [:visitor, :member, :creator, :owner, :participant, :admin],
    role_assignment_schema: Core.Authorization.RoleAssignment

  use Core.BundleOverrides

  require Logger

  import Ecto.Query
  alias Ecto.Multi
  alias Core.Repo
  alias Frameworks.GreenLight

  Frameworks.GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  Core.BundleOverrides.grants()

  # Models
  grant_access(Systems.Advert.Model, [:visitor, :member])
  grant_access(Systems.Questionnaire.ToolModel, [:owner, :participant])
  grant_access(Systems.Lab.ToolModel, [:owner, :participant])

  # Pages
  grant_access(CoreWeb.FakeQualtrics, [:member])
  grant_access(Systems.Account.AwaitConfirmation, [:visitor])
  grant_access(Systems.Account.ConfirmToken, [:visitor])
  grant_access(Systems.Account.ResetPassword, [:visitor])
  grant_access(Systems.Account.ResetPasswordToken, [:visitor])
  grant_access(Systems.Account.SignupPage, [:visitor])
  grant_access(Systems.Account.UserProfilePage, [:member])
  grant_access(Systems.Account.UserSecuritySettings, [:member])
  grant_access(Systems.Account.UserSettings, [:member])
  grant_access(Systems.Account.UserSignin, [:visitor])
  grant_access(Systems.Admin.ConfigPage, [:admin])
  grant_access(Systems.Admin.ImportRewardsPage, [:admin])
  grant_access(Systems.Admin.LoginPage, [:visitor, :member])
  grant_access(Systems.Advert.ContentPage, [:owner])
  grant_access(Systems.Advert.OverviewPage, [:creator])
  grant_access(Systems.Alliance.CallbackPage, [:owner])
  grant_access(Systems.Assignment.ContentPage, [:owner])
  grant_access(Systems.Assignment.CrewPage, [:participant, :tester])
  grant_access(Systems.Assignment.LandingPage, [:participant])
  grant_access(Systems.Budget.FundingPage, [:admin, :creator])
  grant_access(Systems.Desktop.Page, [:creator])
  grant_access(Systems.Feldspar.AppPage, [:visitor, :member])
  grant_access(Systems.Graphite.LeaderboardContentPage, [:owner])
  grant_access(Systems.Graphite.LeaderboardPage, [:owner, :participant, :tester])
  grant_access(Systems.Home.Page, [:visitor, :member, :creator])
  grant_access(Systems.Lab.PublicPage, [:member])
  grant_access(Systems.Manual.Builder.PublicPage, [:creator])
  grant_access(Systems.NextAction.OverviewPage, [:member])
  grant_access(Systems.Notification.OverviewPage, [:member])
  grant_access(Systems.Onyx.LandingPage, [:admin])
  grant_access(Systems.Org.ContentPage, [:admin])
  grant_access(Systems.Pool.DetailPage, [:creator])
  grant_access(Systems.Pool.LandingPage, [:visitor, :member, :owner])
  grant_access(Systems.Pool.ParticipantPage, [:creator])
  grant_access(Systems.Pool.SubmissionPage, [:creator])
  grant_access(Systems.Project.NodePage, [:owner])
  grant_access(Systems.Project.OverviewPage, [:admin, :creator])
  grant_access(Systems.Promotion.LandingPage, [:visitor, :member])
  grant_access(Systems.Storage.EndpointContentPage, [:owner])
  grant_access(Systems.Support.HelpdeskPage, [:member])
  grant_access(Systems.Support.OverviewPage, [:admin])
  grant_access(Systems.Support.TicketPage, [:admin])
  grant_access(Systems.Test.Page, [:visitor, :member])

  grant_actions(CoreWeb.FakeAllianceController, %{
    index: [:visitor, :member]
  })

  def get_node!(id), do: Repo.get!(Core.Authorization.Node, id)

  def prepare_node() do
    %Core.Authorization.Node{}
  end

  def prepare_node(nil) do
    %Core.Authorization.Node{}
  end

  def prepare_node(roles) when is_list(roles) do
    %Core.Authorization.Node{role_assignments: roles}
  end

  def prepare_node(parent_id) when is_integer(parent_id) do
    %Core.Authorization.Node{parent_id: parent_id}
  end

  def prepare_node(%Core.Authorization.Node{id: parent_id}) do
    %Core.Authorization.Node{parent_id: parent_id}
  end

  def prepare_node(principals, role) when is_list(principals) do
    roles = Enum.map(principals, &prepare_role(&1, role))
    prepare_node(roles)
  end

  def prepare_node(principal, role) do
    prepare_node([principal], role)
  end

  def prepare_role(%{} = principal, role) when is_atom(role) do
    GreenLight.Principal.id(principal)
    |> prepare_role(role)
  end

  def prepare_role(principal_id, role) when is_integer(principal_id) and is_atom(role) do
    %Core.Authorization.RoleAssignment{
      principal_id: principal_id,
      role: role
    }
  end

  def prepare_role(%Core.Authorization.Node{id: node_id}, principal, role) when is_atom(role) do
    principal_id = GreenLight.Principal.id(principal)

    %Core.Authorization.RoleAssignment{
      principal_id: principal_id,
      role: role,
      node_id: node_id
    }
  end

  def create_node(parent \\ nil) do
    case prepare_node(parent) |> Core.Repo.insert() do
      {:ok, node} -> {:ok, node.id}
      error -> error
    end
  end

  def create_node!(parent \\ nil) do
    case prepare_node(parent) |> Core.Repo.insert() do
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

  def copy(
        %Core.Authorization.Node{role_assignments: role_assignments},
        %Core.Authorization.Node{} = new_parent
      )
      when is_list(role_assignments) do
    auth_node = create_node!(new_parent)

    role_assignments
    |> Enum.each(&copy_role(&1, auth_node))

    auth_node
  end

  def copy_auth_node(%{auth_node: auth_node}, %Core.Authorization.Node{} = new_parent) do
    copy(auth_node, new_parent)
  end

  def copy_auth_node(%{auth_node: child_auth_node}, %{auth_node: parent_auth_node}) do
    copy(child_auth_node, parent_auth_node)
  end

  def copy_auth_node(%{auth_node: auth_node}) do
    copy(auth_node)
  end

  def copy_role(%Core.Authorization.RoleAssignment{} = role, node) do
    %Core.Authorization.RoleAssignment{}
    |> Core.Authorization.RoleAssignment.changeset(Map.from_struct(role))
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Repo.insert!()
  end

  def delete_role_assignments(%Core.Authorization.Node{id: node_id}) do
    from(ra in Core.Authorization.RoleAssignment, where: ra.node_id == ^node_id)
    |> Core.Repo.delete_all()
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

  def roles_intersect?(principal, entity, roles) do
    nodes_query = entity |> parent_node_query

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

  def can_access?(nil, _entity, _module), do: false

  def can_access?(_principal, nil, _module), do: false

  def can_access?(principal, entity, module) when is_atom(module) do
    can?(principal, entity, GreenLight.Permissions.access_permission(module))
  end

  def can?(principal, entity, permission) when is_binary(permission) do
    can?(principal, permission) or
      has_required_roles_in_context?(principal, entity, permission)
  end

  def users_with_role(_, _, preload \\ [])

  def users_with_role(node_id, role, preload) when is_number(node_id) do
    principal_ids = query_principal_ids(node_id: node_id, role: role)

    Ecto.Query.from(u in Systems.Account.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload
    )
    |> Core.Repo.all()
  end

  def users_with_role(entity, role, preload) do
    principal_ids = query_principal_ids(role: role, entity: entity)

    Ecto.Query.from(u in Systems.Account.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload
    )
    |> Core.Repo.all()
  end

  def user_has_role?(%{id: user_id}, entity, role) do
    user_has_role?(user_id, entity, role)
  end

  def user_has_role?(user_id, entity, role) do
    users_with_role(entity, role)
    |> Enum.any?(&(&1.id == user_id))
  end

  def first_user_with_role(entity, role, preload) do
    user =
      entity
      |> users_with_role(role, preload)
      |> List.first()

    case user do
      nil ->
        Logger.error("No user found with role #{role} for #{entity}")
        {:error}

      user ->
        {:ok, user}
    end
  end

  def top_entity(%{auth_node_id: _auth_node_id} = entity) do
    entity
    |> get_parent_nodes()
    |> List.last()
  end

  def link(auth_tree) do
    Multi.new()
    |> link(auth_tree)
    |> Repo.transaction()
  end

  def link(multi, {parent, [h | t]}) do
    multi
    |> link({parent, h})
    |> link({parent, t})
  end

  def link(
        multi,
        {%Core.Authorization.Node{} = parent, {%Core.Authorization.Node{} = child, subtree}}
      ) do
    multi
    |> link({parent, child})
    |> link({child, subtree})
  end

  def link(multi, {%Core.Authorization.Node{} = parent, %Core.Authorization.Node{} = child}) do
    link(multi, parent, child)
  end

  def link(multi, {_, _}), do: multi

  def link(
        multi,
        %Core.Authorization.Node{} = parent,
        %Core.Authorization.Node{parent: %Ecto.Association.NotLoaded{}} = child
      ) do
    link(multi, parent, Repo.preload(child, :parent))
  end

  def link(multi, %Core.Authorization.Node{} = parent, %Core.Authorization.Node{} = child) do
    changeset =
      Core.Authorization.Node.change(child)
      |> Ecto.Changeset.put_assoc(:parent, parent)

    Multi.update(multi, Ecto.UUID.generate(), changeset)
  end

  def print_roles(%{auth_node_id: node_id} = entity) do
    print_roles(node_id)
    entity
  end

  def print_roles(%Core.Authorization.Node{id: node_id} = node) do
    print_roles(node_id)
    node
  end

  def print_roles(node_id) when is_integer(node_id) do
    Logger.notice(
      "------------------------------------------------------------------------------------------"
    )

    node_id
    |> get_parent_nodes()
    |> Enum.each(fn node_id ->
      roles =
        from(ra in Core.Authorization.RoleAssignment, where: ra.node_id == ^node_id)
        |> Core.Repo.all()
        |> Enum.map(fn %{role: role, principal_id: principal_id} ->
          "##{principal_id} => :#{role}"
        end)

      if Enum.empty?(roles) do
        Logger.notice("0 roles for #{find_entity(node_id)} ##{node_id}", ansi_color: :blue)
      else
        Logger.notice(
          "#{Enum.count(roles)} roles for #{find_entity(node_id)} ##{node_id}: [#{roles |> Enum.join(", ")}]",
          ansi_color: :magenta
        )
      end
    end)

    Logger.notice(
      "------------------------------------------------------------------------------------------"
    )
  end

  @entities [
    Systems.Project.Model,
    Systems.Project.NodeModel,
    Systems.Workflow.Model,
    Systems.Assignment.Model,
    Systems.Storage.EndpointModel,
    Systems.Crew.Model,
    Systems.Graphite.ToolModel,
    Systems.Graphite.LeaderboardModel
  ]

  defp find_entity(node_id) do
    @entities
    |> Enum.reduce("Unkown", fn entity, acc ->
      if from(e in entity, where: e.auth_node_id == ^node_id)
         |> Core.Repo.exists?() do
        entity
        |> Atom.to_string()
        |> String.replace("Elixir.Systems.", "")
      else
        acc
      end
    end)
  end
end
