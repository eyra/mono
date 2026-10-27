defmodule Systems.Probe.System do
  @moduledoc "The Probe assignment template (`config :core, assignment_templates:`)."
  use Core.System

  def feature_flags, do: [:probe]
end
