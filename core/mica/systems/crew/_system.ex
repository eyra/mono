defmodule Systems.Crew.System do
  use Core.System

  def signal_handlers, do: [Systems.Crew.Switch]
end
