defmodule Systems.Project.Assembly do
  alias Core.Repo
  alias Ecto.Multi
  alias Ecto.Changeset
  import Ecto.Query, warn: false
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Signal
  alias Core.Authorization

  alias Systems.Project
  alias Systems.Assignment

  def delete(%Project.Model{auth_node: %{id: node_id}}) do
    from(ra in Authorization.RoleAssignment,
      where: ra.node_id == ^node_id
    )
    |> Repo.delete_all()
  end

  def delete(%Project.ItemModel{id: id} = item) do
    items =
      from(item in Project.ItemModel,
        where: item.id == ^id
      )

    Multi.new()
    |> Multi.delete_all(:items, items)
    |> Multi.put(:project_item, item)
    |> EctoHelper.run(:project_node, &load_node!/1)
    |> Signal.Public.multi_dispatch({:project_node, :delete_item})
    |> Repo.transaction()
  end

  def create(name, user, :empty) do
    project = prepare_project(name, [], user)

    Multi.new()
    |> Multi.insert(:project, project)
    |> EctoHelper.run(:auth, &update_auth/2)
    |> Repo.transaction()
  end

  def create(name, user, template) do
    items = prepare_items(template)
    project = prepare_project(name, items, user)

    Multi.new()
    |> Multi.insert(:project, project)
    |> EctoHelper.run(:auth, &update_auth/2)
    |> EctoHelper.run(:path, &update_path/2)
    |> Repo.transaction()
  end

  def create_item(template, name, %Project.NodeModel{} = node)
      when is_binary(name) do
    Multi.new()
    |> Multi.insert(
      :project_item,
      prepare_item(template, name)
      |> Changeset.put_assoc(:node, node)
    )
    |> EctoHelper.run(:project_node, &load_node!/1)
    |> EctoHelper.run(:auth, &update_auth/2)
    |> EctoHelper.run(:path, &update_path/2)
    |> Signal.Public.multi_dispatch({:project_node, :create_and_dispatch})
    |> Repo.transaction()
  end

  # LOAD

  defp load_node!(%{project_item: %{node_id: node_id}}) do
    {:ok, Project.Public.get_node!(node_id, Project.NodeModel.preload_graph(:down))}
  end

  # PREPARE

  defp prepare_project(name, items, user) when is_list(items) do
    Project.Public.prepare(%{name: name}, items, user)
  end

  defp prepare_items(:data_donation) do
    [prepare_item(:data_donation, "Data Donation Assignment")]
  end

  defp prepare_items(:benchmark) do
    [
      prepare_item(:benchmark_challenge, "Benchmark Challenge")
    ]
  end

  defp prepare_item(:benchmark_challenge, name) do
    {:ok, assignment} =
      Assignment.Assembly.prepare(:benchmark_challenge, :project, nil)
      |> Changeset.apply_action(:prepare)

    Project.Public.prepare_item(%{name: name, project_path: []}, assignment)
  end

  defp prepare_item(:data_donation, name) do
    {:ok, assignment} =
      Assignment.Assembly.prepare(:data_donation, :project, nil)
      |> Changeset.apply_action(:prepare)

    Project.Public.prepare_item(%{name: name, project_path: []}, assignment)
  end

  # PROJECT PATH
  def update_path(multi, %{project: project}), do: update_path(multi, project)

  def update_path(multi, %{project_node: %{project_path: project_path} = node}),
    do: update_path(multi, node, project_path)

  def update_path(multi, %Project.Model{id: id, root: root}) do
    update_path(multi, root, [id])
  end

  def update_path(
        multi,
        %Project.NodeModel{children: %Ecto.Association.NotLoaded{}} = node,
        project_path
      ) do
    update_path(multi, Repo.preload(node, :children), project_path)
  end

  def update_path(
        multi,
        %Project.NodeModel{items: %Ecto.Association.NotLoaded{}} = node,
        project_path
      ) do
    update_path(multi, Repo.preload(node, :items), project_path)
  end

  def update_path(
        multi,
        %Project.NodeModel{id: id, items: items, children: children} = node,
        project_path
      ) do
    changeset = Project.NodeModel.changeset(node, %{project_path: project_path})
    new_project_path = append_path(project_path, node)

    multi
    |> Multi.update("node_#{id}", changeset)
    |> update_paths(items, new_project_path)
    |> update_paths(children, new_project_path)
  end

  def update_path(multi, %Project.ItemModel{id: id} = item, project_path) do
    changeset = Project.ItemModel.changeset(item, %{project_path: project_path})

    Multi.update(multi, "item_#{id}", changeset)
  end

  def update_paths(multi, [_ | _] = elements, project_path) do
    Enum.reduce(elements, multi, fn element, multi ->
      update_path(multi, element, project_path)
    end)
  end

  def update_paths(multi, _, _parent_path), do: multi

  def append_path(path, %{id: id}) when is_list(path), do: append_path(path, id)

  def append_path(path, sub_path) when is_list(path) and is_integer(sub_path),
    do: path ++ [sub_path]

  # AUTHORIZATION

  def update_auth(multi, %{project: project}), do: update_auth(multi, project)
  def update_auth(multi, %{project_node: node}), do: update_auth(multi, node)
  def update_auth(multi, %{project_item: item}), do: update_auth(multi, item)

  def update_auth(multi, %Project.Model{} = project) do
    auth_tree = Project.Model.auth_tree(project)
    Authorization.link(multi, auth_tree)
  end

  def update_auth(multi, %Project.NodeModel{} = project) do
    auth_tree = Project.NodeModel.auth_tree(project)
    Authorization.link(multi, auth_tree)
  end

  def update_auth(multi, %Project.ItemModel{} = project) do
    auth_tree = Project.ItemModel.auth_tree(project)
    Authorization.link(multi, auth_tree)
  end
end
