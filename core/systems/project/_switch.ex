defmodule Systems.Project.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal

  alias Systems.{
    Project
  }

  @impl true
  def intercept({:alliance_tool, _} = signal, %{alliance_tool: tool} = message),
    do: handle({:tool, signal}, Map.merge(message, %{tool: tool}))

  @impl true
  def intercept({:lab_tool, _} = signal, %{lab_tool: tool} = message),
    do: handle({:tool, signal}, Map.merge(message, %{tool: tool}))

  @impl true
  def intercept({:feldspar_tool, _} = signal, %{feldspar_tool: tool} = message),
    do: handle({:tool, signal}, Map.merge(message, %{tool: tool}))

  @impl true
  def intercept({:document_tool, _} = signal, %{document_tool: tool} = message),
    do: handle({:tool, signal}, Map.merge(message, %{tool: tool}))

  @impl true
  def intercept({:benchmark_tool, _} = signal, %{benchmark_tool: tool} = message),
    do: handle({:tool, signal}, Map.merge(message, %{tool: tool}))

  @impl true
  def intercept({:tool_ref, _} = signal, %{tool_ref: tool_ref} = message) do
    if project_item = Project.Public.get_item_by_tool_ref(tool_ref) do
      dispatch!(
        {:project_item, signal},
        Map.merge(message, %{project_item: project_item})
      )
    end
  end

  @impl true
  def intercept({:project_node, _} = signal, %{project_node: project_node} = message) do
    update_pages(project_node)

    if project = Project.Public.get_by_root(project_node) do
      dispatch!(
        {:project, signal},
        Map.merge(message, %{project: project})
      )
    end
  end

  @impl true
  def intercept({:project, _}, %{project: project}) do
    update_pages(project)
  end

  defp handle({:tool, signal}, %{tool: tool} = message) do
    Project.Public.get_tool_ref_by_tool(tool)
    |> then(&dispatch!({:tool_ref, signal}, Map.merge(message, %{tool_ref: &1})))
  end

  defp update_pages(%Project.NodeModel{} = node) do
    [Project.NodePage]
    |> Enum.each(&update_page(&1, node))
  end

  defp update_pages(%Project.Model{} = project) do
    Project.Public.list_owners(project)
    |> Enum.each(fn user ->
      update_page(Project.OverviewPage, user)
    end)
  end

  defp update_page(page, %{id: id} = model) when is_atom(page) do
    dispatch!({:page, page}, %{id: id, model: model})
  end
end
