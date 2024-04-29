defmodule Systems.Graphite.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Graphite

  @impl true
  def view_model(page, %Graphite.LeaderboardModel{} = tool, assigns) do
    builder(page).view_model(tool, assigns)
  end

  defp builder(Graphite.LeaderboardPage), do: Graphite.LeaderboardPageBuilder
  defp builder(Graphite.LeaderboardContentPage), do: Graphite.LeaderboardContentPageBuilder
end
