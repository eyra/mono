defmodule Storybook.Systems.Graphite.SubmissionView.List do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Graphite.SubmissionView.list/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Submissions of a challenge",
        attributes: %{
          items: [
            %{
              team: "Team Tilburg",
              description: "Gradient boosted trees",
              summary: "Submitted yesterday at 14:32",
              url: "https://github.com/eyra/fertility-prediction-challenge/commit/3f2a9c1",
              buttons: []
            },
            %{
              team: "Utrecht Data School",
              description: "Logistic regression",
              summary: "Submitted Monday at 09:15",
              url: "https://github.com/eyra/fertility-prediction-challenge/commit/b71e04d",
              buttons: []
            }
          ]
        }
      }
    ]
  end
end
