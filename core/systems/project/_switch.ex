defmodule Systems.Project.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal
  alias Systems.Project

  @impl true
  def intercept({:project_item, _} = signal, %{project_item: project_item} = message) do
    project_node = Project.Public.get_node_by_item!(project_item)

    dispatch!(
      {:project_node, signal},
      Map.merge(message, %{project_node: project_node})
    )

    :ok
  end

  @impl true
  def intercept({:project_node, _} = signal, %{project_node: project_node} = message) do
    from_pid = Map.get(message, :from_pid, self())
    update_pages(project_node, from_pid)

    if project = Project.Public.get_by_root(project_node) do
      dispatch!(
        {:project, signal},
        Map.merge(message, %{project: project})
      )
    end

    :ok
  end

  @impl true
  def intercept({:project, _}, %{project: project} = message) do
    from_pid = Map.get(message, :from_pid, self())
    update_pages(project, from_pid)
    :ok
  end

  defp update_pages(%Project.NodeModel{} = node, from_pid) do
    [Project.NodePage]
    |> Enum.each(&update_page(&1, node, from_pid))
  end

  defp update_pages(%Project.Model{} = project, from_pid) do
    Project.Public.list_owners(project)
    |> Enum.each(fn user ->
      update_page(Project.OverviewPage, user, from_pid)
    end)
  end

  defp update_page(page, %{id: id} = model, from_pid) when is_atom(page) do
    dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
