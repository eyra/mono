defmodule Systems.Feldspar.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Feldspar

  @impl true
  def intercept(
        {:feldspar_tool, _},
        %{feldspar_tool: tool, from_pid: from_pid}
      ) do
    update_tool_view(tool, from_pid)
    :ok
  end

  @impl true
  def intercept({:feldspar_tool, _}, _message) do
    # Handle case without from_pid
    :ok
  end

  defp update_tool_view(tool, from_pid) do
    dispatch!({:embedded_live_view, Feldspar.ToolView}, %{
      id: tool.id,
      model: tool,
      from_pid: from_pid
    })
  end
end
