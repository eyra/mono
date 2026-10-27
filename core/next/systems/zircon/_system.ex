defmodule Systems.Zircon.System do
  use Core.System

  def signal_handlers, do: [Systems.Zircon.Switch]
end
