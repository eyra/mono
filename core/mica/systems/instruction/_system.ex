defmodule Systems.Instruction.System do
  use Mica.System

  def tools, do: [Systems.Instruction.Tool]

  def signal_handlers, do: [Systems.Instruction.Switch]
end
