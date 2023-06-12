defmodule Systems.Project.Assembly do
  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Utility.EctoHelper
  alias Core.Authorization

  alias Systems.{
    Project,
    DataDonation,
    Benchmark
  }

  def delete(%Project.Model{root: root, auth_node: auth_node}) do
    Multi.new()
    |> EctoHelper.delete(:root, root)
    |> Multi.delete(:auth_node, auth_node)
    |> Repo.transaction()
  end

  def create(name, user, :data_donation) do
    Multi.new()
    |> prepare_project(name, user)
    |> prepare_tool_ref(0, :data_donation)
    |> prepare_item(0, "Data Donation Study")
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

  defp prepare_tool_ref(multi, index, :data_donation) do
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

  defp prepare_tool_ref(multi, index, :benchmark) do
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
end
