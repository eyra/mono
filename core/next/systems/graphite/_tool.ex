defmodule Next.Systems.Graphite.Tool do
  @moduledoc "The `graphite` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "graphite"

  @impl true
  def schema, do: Next.Systems.Graphite.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Next.Systems.Graphite.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Next.Systems.Graphite.ToolView
end
