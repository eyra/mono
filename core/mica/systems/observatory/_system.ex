defmodule Systems.Observatory.System do
  use Core.System

  def signal_handlers, do: [Systems.Observatory.Switch]
end
