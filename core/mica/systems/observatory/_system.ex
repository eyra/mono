defmodule Systems.Observatory.System do
  use Mica.System

  def signal_handlers, do: [Systems.Observatory.Switch]
end
