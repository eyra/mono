defmodule Systems.Project.Assembly do
  import Ecto.Query, warn: false
  use Gettext, backend: CoreWeb.Gettext

  require Logger
  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Frameworks.Utility.EctoHelper
  alias Systems.Storage
  alias Systems.Assignment
  alias Systems.Project

  def template(%Project.ItemModel{} = item) do
    item
    |> Project.ItemModel.special()
    |> template()
  end

  def template(%Assignment.Model{special: template}), do: template
  def template(_), do: nil

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

  @spec create(any(), any(), :empty) :: any()
  def create(name, user, :empty) do
    project_changeset = prepare_project(name, [], user)

    transaction_result =
      Multi.new()
      |> Multi.insert(:project, project_changeset)
      |> EctoHelper.run(:auth, &update_auth/2)
      |> Repo.transaction()

    project =
      case transaction_result do
        {:ok, %{project: project}} ->
          project

        {:error, failed_operation, failed_value, _changes} ->
          Logger.warning("Transaction failed at #{failed_operation}")
          nil
      end

    if project do
      project = Repo.preload(project, :root)

      changeset =
        Storage.Public.prepare_endpoint(:builtin, %{key: "project_node=#{project.root.id}"})

      if changeset.valid? do
        create_item(changeset, dgettext("eyra-storage", "default.name"), project.root)
      else
        Logger.warning("Failed to prepare storage endpoint")
        {:error, changeset}
      end
    else
      {:error, "Project creation failed"}
    end
  end

  def create_item(template_or_changeset, name, %Project.NodeModel{} = node)
      when is_binary(name) do
    Multi.new()
    |> Multi.insert(
      :project_item,
      prepare_item(template_or_changeset, name)
      |> Changeset.put_assoc(:node, node)
    )
    |> EctoHelper.run(:project_node, &load_node!/1)
    |> EctoHelper.run(:auth, &update_auth/2)
    |> EctoHelper.run(:path, &update_path/2)
    |> Signal.Public.multi_dispatch({:project_item, :inserted})
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

  defp prepare_item(:questionnaire, name) do
    {:ok, assignment} =
      Assignment.Assembly.prepare(:questionnaire, :project, nil)
      |> Changeset.apply_action(:prepare)

    Project.Public.prepare_item(%{name: name, project_path: []}, assignment)
  end

  defp prepare_item(:paper_screening, name) do
    {:ok, assignment} =
      Assignment.Assembly.prepare(:paper_screening, :project, nil)
      |> Changeset.apply_action(:prepare)

    Project.Public.prepare_item(%{name: name, project_path: []}, assignment)
  end

  defp prepare_item(%Ecto.Changeset{} = changeset, name) do
    Project.Public.prepare_item(%{name: name, project_path: []}, changeset)
  end

  # PROJECT PATH
  def update_path(multi, %{project: project}), do: update_path(multi, project)

  def update_path(multi, %{project_node: %{project_path: project_path} = node}),
    do: update_path(multi, node, project_path)

  def update_path(multi, %Project.Model{id: id, root: root}) do
    update_path(multi, root, [id])
  end

  @spec update_path(
          Ecto.Multi.t(),
          %{
            :__struct__ => Systems.Project.ItemModel | Systems.Project.NodeModel,
            optional(atom()) => any()
          },
          any()
        ) :: any()
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
