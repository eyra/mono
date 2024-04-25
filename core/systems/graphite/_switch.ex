defmodule Systems.Graphite.Switch do
  use Frameworks.Signal.Handler
  require Logger

  alias Frameworks.Signal
  alias Systems.Graphite
  alias Systems.Assignment

  @impl true
  def intercept(
        {:project_item, _} = signal,
        %{project_item: %{leaderboard: %{tool: tool}}} = message
      ) do
    if assignment = Assignment.Public.get_by_tool(tool, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept(
        {:graphite_tool, _} = signal,
        %{graphite_tool: tool} = message
      ) do
    if assignment = Assignment.Public.get_by_tool(tool, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept(
        {:graphite_leaderboard, _},
        %{graphite_leaderboard: leaderboard, from_pid: from_pid}
      ) do
    update_pages(leaderboard, from_pid)
    :ok
  end

  @impl true
  def intercept(
        {:assignment, _},
        %{assignment: %{special: :benchmark_challenge} = assignment, from_pid: from_pid}
      ) do
    Graphite.Public.list_leaderboards(assignment, Graphite.LeaderboardModel.preload_graph(:down))
    |> Enum.each(&update_pages(&1, from_pid))

    :ok
  end

  defp update_pages(%Graphite.LeaderboardModel{} = leaderboard, from_pid) do
    [
      Graphite.LeaderboardPage,
      Graphite.LeaderboardContentPage
    ]
    |> Enum.each(&update_page(&1, leaderboard, from_pid))
  end

  defp update_page(page, model, from_pid) do
    dispatch!({:page, page}, %{id: model.id, model: model, from_pid: from_pid})
  end
end
