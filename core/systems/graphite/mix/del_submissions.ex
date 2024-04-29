defmodule Mix.Tasks.Core.Graphite.Del.Submissions do
  @moduledoc """
  Remove Submissions generated with the generate submissions command.

  Usage:
    $ mix core.graphite.del.submissions PREFIX
  """
  use Mix.Task

  alias Systems.Graphite

  @shortdoc "Remove Graphite submissions"
  def run(args) do
    Mix.Task.run("app.start")

    if length(args) == 1 do
      delete_submissions(List.first(args))
    else
      print_usage()
    end
  end

  defp delete_submissions(prefix) do
    Graphite.Gen.delete_submissions(prefix)
  end

  defp print_usage() do
    IO.puts("""
    Please provide a single argument: the prefix for the records to be removed.
    """)
  end
end
