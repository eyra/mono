defmodule Next.Systems.Probe.System do
  @moduledoc "The Probe assignment template (`config :mica, assignment_templates:`)."
  use Mica.System

  def feature_flags, do: [:probe]
end
