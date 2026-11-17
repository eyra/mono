defmodule Systems.Lab.Tool do
  @moduledoc "The `lab` tool type (`Mica.Tool`). It has no participant `ToolView`, so `view/0` is `nil`."
  use Mica.Tool

  @impl true
  def type, do: "lab"

  @impl true
  def schema, do: Systems.Lab.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Lab.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: nil
end
