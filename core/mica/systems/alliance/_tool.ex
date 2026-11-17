defmodule Systems.Alliance.Tool do
  @moduledoc "The `alliance` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "alliance"

  @impl true
  def schema, do: Systems.Alliance.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Alliance.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Systems.Alliance.ToolView
end
