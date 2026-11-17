defmodule Mix.Tasks.Mica.Registry.Check do
  @shortdoc "Count tool refs and project items whose reference doesn't hold"
  @moduledoc """
  Prints `Mica.Registry.Integrity.check/0` and exits with status 1 when a reference
  doesn't hold (a missing target or an unknown type). It reads only; it never
  removes anything.

      mix mica.registry.check
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    counts = Mica.Registry.Integrity.check()
    Mix.shell().info(inspect(counts, pretty: true))

    if Mica.Registry.Integrity.problems?(counts) do
      Mix.raise("mica.registry.check: some references don't hold")
    end
  end
end
