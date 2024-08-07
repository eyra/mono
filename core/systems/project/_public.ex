defmodule Systems.Project.Public do
  use CoreWeb, :verified_routes
  @behaviour Frameworks.Concept.Molecule.Factory

  import CoreWeb.Gettext
  import Ecto.Query, warn: false
  import Systems.Project.Queries

  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Multi

  alias Frameworks.Signal
  alias Frameworks.Concept

  alias Systems.Account.User
  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Graphite
  alias Systems.Project
  alias Systems.Storage
  alias Systems.Workflow

  @impl true
  def name(:parent, %Systems.Storage.EndpointModel{} = model) do
    case get_by_item_special(model) do
      %{name: name} -> {:ok, name}
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def name(:self, %Systems.Storage.EndpointModel{} = model) do
    case get_item_by(model) do
      %{name: name} -> {:ok, name}
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def name(_, _), do: {:error, :not_supported}

  @impl true
  def hierarchy(atom) do
    if item = get_item_by(atom) do
      breadcrumbs(item)
    else
      {:error, :unknown}
    end
  end

  def breadcrumbs(%Project.ItemModel{name: name} = item) do
    special_path = "/#{Concept.Atom.resource_id(item)}/content"
    special_breadcrumb = %{label: name, path: special_path}

    {:ok, node_breadcrumbs} =
      item
      |> get_node_by_item!()
      |> breadcrumbs()

    {:ok, node_breadcrumbs ++ [special_breadcrumb]}
  end

  def breadcrumbs(%Project.NodeModel{} = node) do
    project = get_by_root(node)
    project_breadcrumb = %{label: project.name, path: "/project/node/#{node.id}"}

    {:ok, [projects_breadcrumb(), project_breadcrumb]}
  end

  defp projects_breadcrumb() do
    %{label: dgettext("eyra-project", "first.breadcrumb.label"), path: ~p"/project"}
  end

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

  def get_by_item_special(special) do
    special
    |> get_item_by()
    |> get_node_by_item!()
    |> get_by_root()
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

  def get_storage_endpoint_by(%Assignment.Model{} = assignment) do
    assignment
    |> Project.Public.get_item_by()
    |> get_storage_endpoint_by()
  end

  def get_storage_endpoint_by(%Project.ItemModel{} = project_item) do
    project_item
    |> Project.Public.get_node_by_item!([:auth_node])
    |> get_storage_endpoint_by()
  end

  def get_storage_endpoint_by(%Project.NodeModel{} = project_node) do
    storage_endpoint_item =
      project_node
      |> Project.Public.list_items(:storage_endpoint, Project.ItemModel.preload_graph(:down))
      |> List.first()

    if storage_endpoint_item do
      {:ok, Map.get(storage_endpoint_item, :storage_endpoint)}
    else
      {:error, {:storage_endpoint, :not_available}}
    end
  end

  def get_item_by(%Assignment.Model{id: assignment_id}) do
    get_item_by_special(:assignment, assignment_id)
  end

  def get_item_by(%Advert.Model{id: advert_id}) do
    get_item_by_special(:advert, advert_id)
  end

  def get_item_by(%Graphite.LeaderboardModel{id: advert_id}) do
    get_item_by_special(:leaderboard, advert_id)
  end

  def get_item_by(%Storage.EndpointModel{id: storage_endpoint_id}) do
    get_item_by_special(:storage_endpoint, storage_endpoint_id)
  end

  defp get_item_by_special(special_name, special_id) do
    item_query_by_special(special_name, special_id)
    |> Repo.one()
    |> Repo.preload(Project.ItemModel.preload_graph(:down))
  end

  @spec list_owned_projects(any()) :: any()
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

  def list_items(_, selector \\ nil, preload \\ [])

  def list_items(%Project.Model{root: node}, selector, preload) do
    list_items(node, selector, preload)
  end

  def list_items(node, nil, preload) do
    item_query(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, :assignment, preload) do
    item_query_by_assignment(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, {:assignment, template}, preload) do
    item_query_by_assignment(node, template)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, :advert, preload) do
    item_query_by_advert(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, :leaderboard, preload) do
    item_query_by_leaderboard(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_items(node, :storage_endpoint, preload) do
    item_query_by_storage_endpoint(node)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def exists?(user, name) do
    list_owned_projects(user)
    |> Enum.find(&(&1.name == name)) != nil
  end

  def item_exists?(project_node, name) do
    list_items(project_node)
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

  def new_item_name(project_node, name) do
    if item_exists?(project_node, name) do
      new_item_name(project_node, name, 2)
    else
      name
    end
  end

  def new_item_name(project_node, name, attempt) do
    new_name = "#{name} (#{attempt})"

    if item_exists?(project_node, new_name) do
      new_item_name(project_node, name, attempt + 1)
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

  def prepare_item(attrs, %Ecto.Changeset{data: %Storage.EndpointModel{}} = changeset) do
    prepare_item(attrs, :storage_endpoint, changeset)
  end

  def prepare_item(attrs, %Ecto.Changeset{data: %Advert.Model{}} = changeset) do
    prepare_item(attrs, :advert, changeset)
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
    Multi.new()
    |> Ecto.Multi.put(:project, project)
    |> Ecto.Multi.put(:user, user)
    |> Multi.run(:add, fn _, %{user: user, project: project} ->
      case Authorization.assign_role(user, project, :owner) do
        :ok -> {:ok, :added}
        error -> {:error, error}
      end
    end)
    |> Signal.Public.multi_dispatch({:project, :add_owner})
    |> Repo.transaction()
  end

  def remove_owner!(%Project.Model{} = project, user) do
    Multi.new()
    |> Ecto.Multi.put(:project, project)
    |> Ecto.Multi.put(:user, user)
    |> Multi.run(:remove, fn _, %{user: user, project: project} ->
      case Authorization.remove_role!(user, project, :owner) do
        {count, _} when count > 0 -> {:ok, :removed}
        error -> {:error, error}
      end
    end)
    |> Signal.Public.multi_dispatch({:project, :remove_owner})
    |> Repo.transaction()
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
