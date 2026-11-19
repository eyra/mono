defmodule Systems.Workflow.System do
  use Mica.System

  def signal_handlers, do: [Systems.Workflow.Switch]

  # Counts the tool refs and project items whose reference doesn't hold (code-registry).
  def oban_crons, do: [registry_integrity: {"30 3 * * *", Mica.Registry.IntegrityWorker}]
end
