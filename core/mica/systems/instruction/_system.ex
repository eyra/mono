defmodule Systems.Instruction.System do
  use Core.System

  def signal_handlers, do: [Systems.Instruction.Switch]
end
