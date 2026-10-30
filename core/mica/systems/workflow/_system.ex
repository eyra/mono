defmodule Systems.Workflow.System do
  use Mica.System

  def signal_handlers, do: [Systems.Workflow.Switch]
end
