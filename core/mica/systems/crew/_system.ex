defmodule Systems.Crew.System do
  use Mica.System

  def signal_handlers, do: [Systems.Crew.Switch]
end
