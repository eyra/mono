defmodule Systems.Instruction.Tool do
  @moduledoc "The `instruction` tool type (`Mica.Tool`)."
  use Mica.Tool

  @impl true
  def type, do: "instruction"

  @impl true
  def schema, do: Systems.Instruction.ToolModel

  @impl true
  def prepare(attrs, %{auth_node: auth_node}),
    do: Systems.Instruction.Public.prepare_tool(attrs, auth_node)

  @impl true
  def view, do: Systems.Instruction.ToolView
end
