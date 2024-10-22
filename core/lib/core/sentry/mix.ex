defmodule Mix.Tasks.Core.Sentry.Gen.TestEvent do
  @moduledoc """
  Generates a Sentry Test Event.

  Usage:
    $ mix core.sentry.gen.testevent
  """

  use Mix.Task

  @shortdoc "Generate Sentry Test Event"
  def run(_args) do
    Mix.Task.run("app.start")
    Core.Sentry.Gen.test_event()
  end
end
