defmodule Next.Systems.Probe.System do
  @moduledoc "The Probe assignment template."
  use Mica.System

  def assignment_templates, do: [Next.Systems.Probe.AssignmentTemplate]

  def feature_flags, do: [:probe]
end
