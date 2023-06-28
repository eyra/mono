defmodule Systems.Project.Assembly do
  alias Core.Repo
  alias Ecto.Multi
  import Ecto.Query, warn: false
  alias Core.Authorization

  alias Systems.{
    Project,
    DataDonation,
    Benchmark
  }

  def delete(%Project.Model{auth_node: %{id: node_id}}) do
    from(ra in Core.Authorization.RoleAssignment,
      where: ra.node_id == ^node_id
    )
    |> Repo.delete_all()
  end

  def delete(%Project.ItemModel{id: id}) do
    from(item in Project.ItemModel,
      where: item.id == ^id
    )
    |> Repo.delete_all()
  end

  def create(name, user, :empty) do
    Multi.new()
    |> prepare_project(name, user)
    |> Repo.transaction()
  end

  def create(name, user, :data_donation) do
    Multi.new()
    |> prepare_project(name, user)
    |> prepare_tool_ref(0, :data_donation)
    |> prepare_item(0, "Data Donation")
    |> Repo.transaction()
  end

  def create(name, user, :benchmark) do
    Multi.new()
    |> prepare_project(name, user)
    |> prepare_tool_ref(0, :benchmark)
    |> prepare_item(0, "Challenge Round 1")
    |> prepare_tool_ref(1, :benchmark)
    |> prepare_item(1, "Challenge Round 2")
    |> Repo.transaction()
  end

  def create_item(name, %Project.NodeModel{id: node_id} = node, tool_special)
      when is_binary(name) do
    project =
      from(p in Project.Model, where: p.root_id == ^node_id, preload: [:auth_node])
      |> Repo.one!()

    Multi.new()
    |> Multi.insert(:auth_node, fn _ ->
      Authorization.make_node(project.auth_node)
    end)
    |> prepare_tool(tool_special)
    |> Multi.insert(:tool_ref, fn %{tool: tool} ->
      key = String.to_existing_atom("#{tool_special}_tool")
      Project.Public.create_tool_ref(key, tool)
    end)
    |> Multi.insert(:item, fn %{tool_ref: tool_ref} ->
      Project.Public.create_item(
        %{name: name, project_path: [project.id, node_id]},
        node,
        tool_ref
      )
    end)
    |> Repo.transaction()
  end

  defp prepare_project(multi, name, user) do
    multi
    |> Project.Public.create(%{name: name})
    |> Multi.run(:assign_role, fn _, %{project: project} ->
      {:ok, Authorization.assign_role(user, project, :owner)}
    end)
  end

  defp prepare_item(multi, index, name) do
    multi
    |> Multi.insert({:item, index}, fn %{
                                         {:tool_ref, ^index} => tool_ref,
                                         project: project,
                                         root: root
                                       } ->
      Project.Public.create_item(
        %{name: name, project_path: [project.id, root.id]},
        root,
        tool_ref
      )
    end)
  end

  defp prepare_tool_ref(multi, index, :data_donation) when is_integer(index) do
    multi
    |> Multi.insert({:tool_auth_node, index}, fn %{root: %{auth_node: auth_node}} ->
      Authorization.make_node(auth_node)
    end)
    |> Multi.insert({:tool, index}, fn %{{:tool_auth_node, ^index} => tool_auth_node} ->
      DataDonation.Public.create(%{subject_count: 0, director: :project}, tool_auth_node)
    end)
    |> Multi.insert({:tool_ref, index}, fn %{{:tool, ^index} => tool} ->
      Project.Public.create_tool_ref(:data_donation_tool, tool)
    end)
  end

  defp prepare_tool_ref(multi, index, :benchmark) when is_integer(index) do
    multi
    |> Multi.insert({:tool_auth_node, index}, fn %{root: %{auth_node: auth_node}} ->
      Authorization.make_node(auth_node)
    end)
    |> Multi.insert({:tool, index}, fn %{{:tool_auth_node, ^index} => tool_auth_node} ->
      Benchmark.Public.create(%{title: "", director: :project}, tool_auth_node)
    end)
    |> Multi.insert({:tool_ref, index}, fn %{{:tool, ^index} => tool} ->
      Project.Public.create_tool_ref(:benchmark_tool, tool)
    end)
  end

  defp prepare_tool(multi, :data_donation) do
    multi
    |> Multi.insert(:tool, fn %{auth_node: auth_node} ->
      DataDonation.Public.create(%{subject_count: 0, director: :project}, auth_node)
    end)
  end

  defp prepare_tool(multi, :benchmark) do
    multi
    |> Multi.insert(:tool, fn %{auth_node: auth_node} ->
      Benchmark.Public.create(%{title: "", director: :project}, auth_node)
    end)
  end
end
