defmodule Systems.Document.Tool do
  @moduledoc "The `document` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "document"

  @impl true
  def schema, do: Systems.Document.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Document.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Systems.Document.ToolView
end
