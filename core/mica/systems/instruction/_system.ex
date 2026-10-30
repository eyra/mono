defmodule Systems.Instruction.System do
  use Mica.System

  def signal_handlers, do: [Systems.Instruction.Switch]
end
