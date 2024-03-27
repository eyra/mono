defmodule Systems.Project.Switch do
  use Frameworks.Signal.Handler

  alias Frameworks.Signal

  alias Systems.{
    Project
  }

  @impl true
  def intercept({:alliance_tool, _} = signal, %{alliance_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:lab_tool, _} = signal, %{lab_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:feldspar_tool, _} = signal, %{feldspar_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:document_tool, _} = signal, %{document_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:graphite_tool, _} = signal, %{graphite_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:instruction_tool, _} = signal, %{instruction_tool: tool} = message) do
    handle({:tool, signal}, Map.merge(message, %{tool: tool}))
    :ok
  end

  @impl true
  def intercept({:tool_ref, _} = signal, %{tool_ref: tool_ref} = message) do
    if project_item = Project.Public.get_item_by_tool_ref(tool_ref) do
      dispatch!(
        {:project_item, signal},
        Map.merge(message, %{project_item: project_item})
      )
    end

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

  defp handle({:tool, signal}, %{tool: tool} = message) do
    if tool_ref = Project.Public.get_tool_ref_by_tool(tool) do
      dispatch!({:tool_ref, signal}, Map.merge(message, %{tool_ref: tool_ref}))
    end
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
