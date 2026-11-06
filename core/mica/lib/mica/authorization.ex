defmodule Mica.Authorization do
  @moduledoc """
  The authorization system for Mica.

  It makes use of the GreenLight framework to manage permissions and
  authorization.
  """
  use Frameworks.GreenLight.Public,
    repo: Mica.Repo,
    roles: [:visitor, :member, :creator, :owner, :participant, :admin],
    role_assignment_schema: Mica.Authorization.RoleAssignment

  require Mica.SaaS

  require Logger

  import Ecto.Query
  alias Ecto.Multi
  alias Mica.Repo
  alias Frameworks.GreenLight

  Frameworks.GreenLight.Permissions.grant(__MODULE__, "test-auth", [:owner])

  Mica.SaaS.grants()

  grant_access(MicaWeb.FakeQualtrics, [:member])
  grant_access(Systems.Test.Page, [:visitor, :member])

  grant_actions(MicaWeb.FakeAllianceController, %{
    index: [:visitor, :member]
  })

  def get_node!(id), do: Repo.get!(Mica.Authorization.Node, id)

  def prepare_node() do
    %Mica.Authorization.Node{}
  end

  def prepare_node(nil) do
    %Mica.Authorization.Node{}
  end

  def prepare_node(roles) when is_list(roles) do
    %Mica.Authorization.Node{role_assignments: roles}
  end

  def prepare_node(parent_id) when is_integer(parent_id) do
    %Mica.Authorization.Node{parent_id: parent_id}
  end

  def prepare_node(%Mica.Authorization.Node{id: parent_id}) do
    %Mica.Authorization.Node{parent_id: parent_id}
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
    %Mica.Authorization.RoleAssignment{
      principal_id: principal_id,
      role: role
    }
  end

  def prepare_role(%Mica.Authorization.Node{id: node_id}, principal, role) when is_atom(role) do
    principal_id = GreenLight.Principal.id(principal)

    %Mica.Authorization.RoleAssignment{
      principal_id: principal_id,
      role: role,
      node_id: node_id
    }
  end

  def create_node(parent \\ nil) do
    case prepare_node(parent) |> Mica.Repo.insert() do
      {:ok, node} -> {:ok, node.id}
      error -> error
    end
  end

  def create_node!(parent \\ nil) do
    case prepare_node(parent) |> Mica.Repo.insert() do
      {:ok, node} -> node
      error -> error
    end
  end

  def copy(%Mica.Authorization.Node{role_assignments: role_assignments})
      when is_list(role_assignments) do
    auth_node = create_node!()

    role_assignments
    |> Enum.each(&copy_role(&1, auth_node))

    auth_node
  end

  def copy(
        %Mica.Authorization.Node{role_assignments: role_assignments},
        %Mica.Authorization.Node{} = new_parent
      )
      when is_list(role_assignments) do
    auth_node = create_node!(new_parent)

    role_assignments
    |> Enum.each(&copy_role(&1, auth_node))

    auth_node
  end

  def copy_auth_node(%{auth_node: auth_node}, %Mica.Authorization.Node{} = new_parent) do
    copy(auth_node, new_parent)
  end

  def copy_auth_node(%{auth_node: child_auth_node}, %{auth_node: parent_auth_node}) do
    copy(child_auth_node, parent_auth_node)
  end

  def copy_auth_node(%{auth_node: auth_node}) do
    copy(auth_node)
  end

  def copy_role(%Mica.Authorization.RoleAssignment{} = role, node) do
    %Mica.Authorization.RoleAssignment{}
    |> Mica.Authorization.RoleAssignment.changeset(Map.from_struct(role))
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Repo.insert!()
  end

  def delete_role_assignments(%Mica.Authorization.Node{id: node_id}) do
    from(ra in Mica.Authorization.RoleAssignment, where: ra.node_id == ^node_id)
    |> Mica.Repo.delete_all()
  end

  defp parent_node_query(entity) do
    initial_query =
      Mica.Authorization.Node |> where([n], n.id == ^GreenLight.AuthorizationNode.id(entity))

    recursion_query =
      Mica.Authorization.Node
      |> join(:inner, [n], nt in "auth_node_parents", on: n.id == nt.parent_id)

    parents_query = initial_query |> union_all(^recursion_query)

    from("auth_node_parents")
    |> recursive_ctes(true)
    |> with_cte("auth_node_parents", as: ^parents_query)
    |> select([n], n.id)
  end

  def get_parent_nodes(node_id) do
    node_id |> parent_node_query |> Mica.Repo.all()
  end

  def roles_intersect?(principal, entity, roles) do
    nodes_query = entity |> parent_node_query

    from(ra in Mica.Authorization.RoleAssignment,
      where:
        ra.node_id in subquery(nodes_query) and ra.role in ^roles and
          ra.principal_id == ^GreenLight.Principal.id(principal)
    )
    |> Mica.Repo.exists?()
  end

  defp has_required_roles_in_context?(principal, entity, permission) do
    roles_with_permission =
      permission_map() |> GreenLight.PermissionMap.roles(permission) |> MapSet.to_list()

    roles_intersect?(principal, entity, roles_with_permission)
  end

  # archplan: guard=authz reason="checks the permission for a page module"
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

  @doc """
  Users with `role` assigned directly on the auth node of `entity`.

  Role assignments on ancestor nodes are ignored. Use `users_with_inherited_role/3`
  when the role is expected to be inherited from higher up the tree, the way
  `can?/3` resolves it.

  An integer argument is interpreted as an auth node id, not as an entity id.
  """
  def users_with_role(_, _, preload \\ [])

  def users_with_role(node_id, role, preload) when is_number(node_id) do
    principal_ids = query_principal_ids(node_id: node_id, role: role)

    Ecto.Query.from(u in Systems.Account.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload,
      order_by: u.id
    )
    |> Mica.Repo.all()
  end

  def users_with_role(entity, role, preload) do
    principal_ids = query_principal_ids(role: role, entity: entity)

    Ecto.Query.from(u in Systems.Account.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload,
      order_by: u.id
    )
    |> Mica.Repo.all()
  end

  @doc """
  Users with `role` assigned on the auth node of `entity` or on any of its ancestors.

  This mirrors the inheritance applied by `can?/3` and `roles_intersect?/3`: a role
  granted on a parent node applies to everything below it. Prefer this over
  `users_with_role/3` whenever the role lives higher up the tree than the entity
  being asked about, e.g. the `:owner` of an assignment, which is assigned on the
  project node.

  An integer argument is interpreted as an auth node id, not as an entity id.
  """
  def users_with_inherited_role(entity, role, preload \\ []) do
    principal_ids =
      from(ra in Mica.Authorization.RoleAssignment,
        where: ra.node_id in subquery(parent_node_query(entity)) and ra.role == ^role,
        select: ra.principal_id
      )

    from(u in Systems.Account.User,
      where: u.id in subquery(principal_ids),
      preload: ^preload,
      order_by: u.id
    )
    |> Mica.Repo.all()
  end

  # archplan: guard=authz reason="checks a role on an entity"
  def user_has_role?(%{id: user_id}, entity, role) do
    user_has_role?(user_id, entity, role)
  end

  def user_has_role?(user_id, entity, role) do
    users_with_role(entity, role)
    |> Enum.any?(&(&1.id == user_id))
  end

  def link(auth_tree) do
    Multi.new()
    |> link(auth_tree)
    |> Repo.commit()
  end

  def link(multi, {parent, [h | t]}) do
    multi
    |> link({parent, h})
    |> link({parent, t})
  end

  def link(
        multi,
        {%Mica.Authorization.Node{} = parent, {%Mica.Authorization.Node{} = child, subtree}}
      ) do
    multi
    |> link({parent, child})
    |> link({child, subtree})
  end

  def link(multi, {%Mica.Authorization.Node{} = parent, %Mica.Authorization.Node{} = child}) do
    link(multi, parent, child)
  end

  def link(multi, {_, _}), do: multi

  def link(
        multi,
        %Mica.Authorization.Node{} = parent,
        %Mica.Authorization.Node{parent: %Ecto.Association.NotLoaded{}} = child
      ) do
    link(multi, parent, Repo.preload(child, :parent))
  end

  def link(multi, %Mica.Authorization.Node{} = parent, %Mica.Authorization.Node{} = child) do
    changeset =
      Mica.Authorization.Node.change(child)
      |> Ecto.Changeset.put_assoc(:parent, parent)

    Multi.update(multi, Ecto.UUID.generate(), changeset)
  end

  def print_roles(%{auth_node_id: node_id} = entity) do
    print_roles(node_id)
    entity
  end

  def print_roles(%Mica.Authorization.Node{id: node_id} = node) do
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
        from(ra in Mica.Authorization.RoleAssignment, where: ra.node_id == ^node_id)
        |> Mica.Repo.all()
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

  defp find_entity(node_id) do
    entities()
    |> Enum.find_value("Unknown", fn entity ->
      if from(e in entity, where: e.auth_node_id == ^node_id) |> Mica.Repo.exists?() do
        entity
        |> Atom.to_string()
        |> String.replace(~r/^Elixir\.(\w+\.)?Systems\./, "")
      end
    end)
  end

  # Every schema that owns an auth node, from Mica and the SaaS alike.
  defp entities do
    {:ok, modules} = :application.get_key(:mica, :modules)

    modules
    |> Enum.sort()
    |> Enum.filter(&owns_auth_node?/1)
  end

  defp owns_auth_node?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__schema__, 2) and
      module.__schema__(:source) != nil and
      match?(
        %Ecto.Association.BelongsTo{related: Mica.Authorization.Node},
        module.__schema__(:association, :auth_node)
      )
  end
end
