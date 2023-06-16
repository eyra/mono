defmodule Systems.Project.Public do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Core.Repo

  alias Core.Accounts.User
  alias Core.Authorization

  alias Systems.{
    Project
  }

  def get!(id, preload \\ []) do
    from(project in Project.Model,
      where: project.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_node!(id, preload \\ []) do
    from(node in Project.NodeModel,
      where: node.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_item!(id, preload \\ []) do
    from(item in Project.ItemModel,
      where: item.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  @doc """
  Returns the list of projects that are owned by the user.
  """
  def list_owned_projects(user, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(s in Project.Model,
      where: s.auth_node_id in subquery(node_ids),
      order_by: [desc: s.updated_at],
      preload: ^preload
    )
    |> Repo.all()
  end

  def delete(id) when is_number(id) do
    get!(id, Project.Model.preload_graph(:full))
    |> Project.Assembly.delete()
  end

  def create(
        %Multi{} = multi,
        %{name: _name} = attrs
      ) do
    multi
    |> Multi.insert(:project_auth_node, Authorization.make_node())
    |> Multi.insert(:root_auth_node, fn %{project_auth_node: project_auth_node} ->
      Authorization.make_node(project_auth_node)
    end)
    |> Multi.insert(:root, fn %{root_auth_node: root_auth_node} ->
      create_node(%{name: "Project", project_path: [0]}, root_auth_node)
    end)
    |> Multi.insert(:project, fn %{root: root, project_auth_node: project_auth_node} ->
      create(attrs, root, project_auth_node)
    end)
    |> Multi.update(:project_path, fn %{project: project, root: root} ->
      update_project_path(root, [project.id])
    end)
  end

  def create(
        %{name: _name} = attrs,
        %Project.NodeModel{} = root,
        %Authorization.Node{} = auth_node
      ) do
    %Project.Model{}
    |> Project.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:root, root)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def create_node(
        %{name: _, project_path: _} = attrs,
        %Authorization.Node{} = auth_node
      ) do
    %Project.NodeModel{}
    |> Project.NodeModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def create_node(
        %{name: _, project_path: _} = attrs,
        children,
        items,
        %Authorization.Node{} = auth_node
      ) do
    %Project.NodeModel{}
    |> Project.NodeModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:children, children)
    |> Ecto.Changeset.put_assoc(:items, items)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def create_item(
        %{name: _name, project_path: _} = attrs,
        %Project.NodeModel{} = node,
        %Project.ToolRefModel{} = tool_ref
      ) do
    %Project.ItemModel{}
    |> Project.ItemModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Ecto.Changeset.put_assoc(:tool_ref, tool_ref)
  end

  def create_tool_ref(tool_key, tool) do
    %Project.ToolRefModel{}
    |> Project.ToolRefModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(tool_key, tool)
  end

  def update_project_path(%Project.NodeModel{} = node, project_path) when is_list(project_path) do
    node
    |> Project.NodeModel.changeset(%{project_path: project_path})
  end

  def update_project_path(%Project.ItemModel{} = item, project_path) when is_list(project_path) do
    item
    |> Project.ItemModel.changeset(%{project_path: project_path})
  end

  def add_item(%Project.ItemModel{} = item, %Project.NodeModel{} = node) do
    item
    |> Project.ItemModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:node, node)
    |> Repo.update()
  end

  def add_node(%Project.NodeModel{} = child, %Project.NodeModel{} = parent) do
    child
    |> Project.NodeModel.changeset(%{})
    |> Ecto.Changeset.put_assoc(:parent, parent)
    |> Repo.update()
  end

  def add_owner!(%Project.Model{} = project, user) do
    :ok = Authorization.assign_role(user, project, :owner)
  end

  def remove_owner!(%Project.Model{} = project, user) do
    Authorization.remove_role!(user, project, :owner)
  end

  def list_owners(%Project.Model{} = project, preload \\ []) do
    owner_ids =
      project
      |> Authorization.list_principals()
      |> Enum.filter(fn %{roles: roles} -> MapSet.member?(roles, :owner) end)
      |> Enum.map(fn %{id: id} -> id end)

    from(u in User, where: u.id in ^owner_ids, preload: ^preload, order_by: u.id) |> Repo.all()
    # AUTH: needs to be marked save. Current user is normally not allowed to
    # access other users.
  end
end
