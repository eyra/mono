defmodule Mix.Tasks.Eyra.Graphite.Gen.Submissions do
  @moduledoc """
  Generate a number of submissions for a `leaderboard`.

  Usage:
    $ mix eyra.graphite.gen.submissions -l LEADERBOARD -n AMOUNT -p PREFIX
  """

  use Mix.Task

  alias Systems.Graphite

  @options [
    strict: [leaderboard: :integer, amount: :integer, prefix: :string],
    aliases: [l: :leaderboard, n: :amount, p: :prefix]
  ]

  @shortdoc "Generate Graphite submissions"
  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, @options) do
      {[leaderboard: id, amount: amount, prefix: prefix], _, _} ->
        create_submissions(id, amount, prefix)

      {[leaderboard: id, amount: amount], _, _} ->
        create_submissions(id, amount, "auto-gen")

      _ ->
        print_missing_arguments()
    end
  end

  defp create_submissions(leaderboard_id, amount, prefix) do
    leaderboard = Graphite.Public.get_leaderboard!(leaderboard_id, [{:tool, :auth_node}])

    multi = Ecto.Multi.new()

    {:ok, result} =
      Enum.reduce(1..amount, multi, fn i, multi ->
        submission =
          Core.Factories.build(:graphite_submission, %{
            tool: leaderboard.tool,
            auth_node: leaderboard.tool.auth_node,
            github_commit_url: gen_commit_url(),
            description: "#{prefix}-#{i}"
          })

        Ecto.Multi.insert(multi, {:insert, i}, submission)
      end)
      |> Core.Repo.transaction(returning: true)

    IO.puts(
      IO.ANSI.green() <>
        "#{length(Map.keys(result))} submissions created" <>
        IO.ANSI.reset()
    )
  end

  defp gen_commit_url() do
    s = for _ <- 1..40, into: "", do: <<Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')>>

    "https://github.com/eyra/mono/commit/" <> s
  end

  defp print_missing_arguments() do
    IO.puts(
      IO.ANSI.red() <>
        """
        An argument seems to be missing. Please specify at least the following:
        -l | --leaderboard: the leaderboard to create the submissions for
        -n | --amount: the amount of submissions to create

        Optional:
        -p | --prefix: prefix to use for the description
        """ <>
        IO.ANSI.reset()
    )
  end
end
