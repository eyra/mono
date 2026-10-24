defmodule Storybook.Systems.Graphite.LeaderboardScoreHTML.Html do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Graphite.LeaderboardScoreHTML.html/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Leaderboard for one metric, ordered by score",
        attributes: %{
          scores: [
            %{
              team: "Team Tilburg",
              description: "Gradient boosted trees on household panel",
              url: "https://example.org/fertility-prediction-challenge/commit/3f2a9c1",
              value: 0.812
            },
            %{
              team: "Utrecht Data School",
              description: "Logistic regression with feature selection",
              url: "https://example.org/fertility-prediction-challenge/commit/b71e04d",
              value: 0.794
            },
            %{
              team: "VU Amsterdam",
              description: "Random forest baseline",
              url: "https://example.org/fertility-prediction-challenge/commit/9c0d5ea",
              value: 0.751
            }
          ]
        }
      },
      %Variation{id: :empty, description: "No scores yet", attributes: %{scores: []}}
    ]
  end
end
