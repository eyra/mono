defmodule Systems.Student.System do
  use Core.System

  def signal_handlers, do: [Systems.Student.Switch]
end
