defmodule Systems.Graphite.Switch do
  use Frameworks.Signal.Handler
  require Logger

  alias Frameworks.Signal
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
end
