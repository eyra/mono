defmodule Systems.Project.Assembly do
  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Utility.EctoHelper
  alias Core.Authorization

  alias Systems.{
    Project,
    DataDonation
  }

  def delete(%Project.Model{root: root, auth_node: auth_node}) do
    Multi.new()
    |> EctoHelper.delete(:root, root)
    |> Multi.delete(:auth_node, auth_node)
    |> Repo.transaction()
  end

  def create(name, user) do
    Multi.new()
    |> Project.Public.create(%{name: name})
    |> Multi.insert(:tool_auth_node, fn %{root: %{auth_node: auth_node}} ->
      Authorization.make_node(auth_node)
    end)
    |> Multi.insert(:tool, fn %{tool_auth_node: tool_auth_node} ->
      DataDonation.Public.create(%{subject_count: 0, director: :project}, tool_auth_node)
    end)
    |> Multi.insert(:tool_ref, fn %{tool: tool} ->
      Project.Public.create_tool_ref(:data_donation_tool, tool)
    end)
    |> Multi.insert(:item, fn %{root: root, tool_ref: tool_ref} ->
      Project.Public.create_item(%{project_path: [0]}, root, tool_ref)
    end)
    |> Multi.run(:assign_role, fn _, %{project: project} ->
      {:ok, Authorization.assign_role(user, project, :owner)}
    end)
    |> Multi.update(:update_root, fn %{project: project, root: root} ->
      Project.Public.update_project_path(root, [project.id])
    end)
    |> Multi.update(:update_item, fn %{project: project, root: root, item: item} ->
      Project.Public.update_project_path(item, [project.id, root.id])
    end)
    |> Repo.transaction()
  end
end
