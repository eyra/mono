defmodule Systems.Feldspar.Tool do
  @moduledoc "The `feldspar` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "feldspar"

  @impl true
  def schema, do: Systems.Feldspar.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Feldspar.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Systems.Feldspar.ToolView
end
