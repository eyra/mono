defmodule Mix.Tasks.Eyra.Graphite.Del.Submissions do
  @moduledoc """
  Remove Submissions generated with the generate submissions command.

  Usage:
    $ mix Eyra.Graphite.Del.Submissions PREFIX
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
    {:ok,
     %{
       submissions: {submission_count, nil},
       users: {user_count, nil}
     }} = Graphite.Gen.delete_submissions(prefix)

    print("#{submission_count} submissions deleted")
    print("#{user_count} users deleted")
  end

  def print(message) do
    IO.puts(IO.ANSI.green() <> message <> IO.ANSI.reset())
  end

  defp print_usage() do
    IO.puts("""
    Please provide a single argument: the prefix for the records to be removed.
    """)
  end
end
