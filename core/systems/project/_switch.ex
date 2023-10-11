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
  def intercept({:project_item, _}, %{project_item: project_item}) do
    update_pages(project_item)
  end

  defp handle({:tool, signal}, %{tool: tool} = message) do
    Project.Public.get_tool_ref_by_tool(tool)
    |> then(&dispatch!({:tool_ref, signal}, Map.merge(message, %{tool_ref: &1})))
  end

  defp update_pages(%Project.ItemModel{} = item) do
    [Project.NodePage]
    |> Enum.each(&update_page(&1, item))
  end

  defp update_page(page, %{id: id} = model) when is_atom(page) do
    dispatch!({:page, page}, %{id: id, model: model})
  end
end
