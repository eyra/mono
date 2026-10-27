defmodule Systems.Workflow.System do
  use Core.System

  def signal_handlers, do: [Systems.Workflow.Switch]
end
