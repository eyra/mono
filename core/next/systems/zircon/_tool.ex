defmodule Next.Systems.Zircon.Tool do
  @moduledoc "The `zircon_screening` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "zircon_screening"

  @impl true
  def schema, do: Next.Systems.Zircon.Screening.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node} = context),
    do:
      Next.Systems.Zircon.Public.prepare_screening_tool(attrs, auth_node, Map.get(context, :user))

  @impl true
  def view, do: Next.Systems.Zircon.Screening.ToolView
end
