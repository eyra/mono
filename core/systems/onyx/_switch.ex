defmodule Systems.Onyx.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Onyx

  def intercept({:onyx_tool_file, :updated} = signal, %{onyx_tool_file: tool_file} = message) do
    tool = Onyx.Public.get_tool!(tool_file.tool_id)

    dispatch!(
      {:onyx_tool, signal},
      Map.merge(message, %{onyx_tool: tool})
    )

    :ok
  end
end
