defmodule Systems.Project.Public do
  import Ecto.Query, warn: false
  import CoreWeb.Gettext
  import Systems.Project.Queries

  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Authorization

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Graphite
  alias Systems.Project

  def get!(id, preload \\ []) do
    from(project in Project.Model,
      where: project.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_by_root(%Project.NodeModel{id: id}, preload \\ []) do
    from(project in Project.Model,
      where: project.root_id == ^id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_node!(id, preload \\ []) do
    from(node in Project.NodeModel,
      where: node.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_node_by_item!(%Project.ItemModel{node_id: node_id}, preload \\ []) do
    get_node!(node_id, preload)
  end

  def get_item!(id, preload \\ []) do
    from(item in Project.ItemModel,
      where: item.id == ^id,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_item_by_assignment(assignment, preload \\ [])

  def get_item_by_assignment(%Assignment.Model{id: assignment_id}, preload) do
    get_item_by_assignment(assignment_id, preload)
  end

  def get_item_by_assignment(assignment_id, preload) do
    from(item in Project.ItemModel,
      where: item.assignment_id == ^assignment_id,
      preload: ^preload
    )
    |> Repo.one()
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

  def list_items(_, _, preload \\ [])

  def list_items(node, {:assignment, template}, preload) do
    item_query_by_assignment(node, template)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, :leaderboard, preload) do
    item_query_by_leaderboard(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def exists?(user, name) do
    list_owned_projects(user)
    |> Enum.find(&(&1.name == name)) != nil
  end

  def new_project_name(user) do
    name = dgettext("eyra-project", "default.name")

    if exists?(user, name) do
      new_project_name(user, name, 2)
    else
      name
    end
  end

  def new_project_name(user, name, attempt) do
    new_name = "#{name} (#{attempt})"

    if exists?(user, new_name) do
      new_project_name(user, name, attempt + 1)
    else
      new_name
    end
  end

  def delete(id) when is_number(id) do
    get!(id, Project.Model.preload_graph(:down))
    |> Project.Assembly.delete()
  end

  def delete_item(id) when is_number(id) do
    get_item!(id, Project.ItemModel.preload_graph(:down))
    |> Project.Assembly.delete()
  end

  def prepare(
        %{name: _name} = attrs,
        items,
        user
      )
      when is_list(items) do
    {:ok, root} =
      prepare_node(%{name: "Project", project_path: []}, items)
      |> Ecto.Changeset.apply_action(:prepare)

    prepare(attrs, root, Authorization.prepare_node(user, :owner))
  end

  def prepare(
        %{name: _name} = attrs,
        %Project.NodeModel{} = root,
        %Authorization.Node{} = auth_node
      ) do
    %Project.Model{}
    |> Project.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:root, root)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_node(
        %{name: _, project_path: _} = attrs,
        items,
        auth_node \\ Authorization.prepare_node()
      )
      when is_list(items) do
    %Project.NodeModel{}
    |> Project.NodeModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:items, items)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_item(attrs, %Workflow.ToolRefModel{} = tool_ref) do
    prepare_item(attrs, :tool_ref, tool_ref)
  end

  def prepare_item(attrs, %Assignment.Model{} = assignment) do
    prepare_item(attrs, :assignment, assignment)
  end

  def prepare_item(attrs, %Graphite.LeaderboardModel{} = leaderboard) do
    prepare_item(attrs, :leaderboard, leaderboard)
  end

  def prepare_item(attrs, %Ecto.Changeset{data: %Graphite.LeaderboardModel{}} = changeset) do
    prepare_item(attrs, :leaderboard, changeset)
  end

  def prepare_item(
        %{name: _name, project_path: _} = attrs,
        field_name,
        concrete
      ) do
    %Project.ItemModel{}
    |> Project.ItemModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(field_name, concrete)
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
  end
end

defimpl Core.Persister, for: Systems.Project.Model do
  def save(_project, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :project) do
      {:ok, %{project: project}} -> {:ok, project}
      _ -> {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Systems.Project.ItemModel do
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Signal
  alias Systems.Project

  def save(_project_item, changeset) do
    result =
      Ecto.Multi.new()
      |> Core.Repo.multi_update(:project_item, changeset)
      |> EctoHelper.run(:project_node, &load_node!/1)
      |> Signal.Public.multi_dispatch({:project_node, :update})
      |> Core.Repo.transaction()

    case result do
      {:ok, %{project_item: project_item}} -> {:ok, project_item}
      _ -> {:error, changeset}
    end
  end

  defp load_node!(%{project_item: %{node_id: node_id}}) do
    {:ok, Project.Public.get_node!(node_id, Project.NodeModel.preload_graph(:down))}
  end
end
