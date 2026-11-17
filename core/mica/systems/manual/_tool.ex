defmodule Systems.Manual.Tool do
  @moduledoc "The `manual` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "manual"

  @impl true
  def schema, do: Systems.Manual.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Manual.Assembly.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Systems.Manual.ToolView
end
