defmodule Systems.Alliance.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Alliance

  @impl true
  def intercept(
        {:alliance_tool, _},
        %{alliance_tool: tool, from_pid: from_pid}
      ) do
    update_tool_view(tool, from_pid)
    :ok
  end

  @impl true
  def intercept({:alliance_tool, _}, _message) do
    # Handle case without from_pid
    :ok
  end

  defp update_tool_view(tool, from_pid) do
    dispatch!({:embedded_live_view, Alliance.ToolView}, %{
      id: tool.id,
      model: tool,
      from_pid: from_pid
    })
  end
end
