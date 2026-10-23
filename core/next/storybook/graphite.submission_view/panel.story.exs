defmodule Storybook.Systems.Graphite.SubmissionView.Panel do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Graphite.SubmissionView.panel/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Submitted solution with timestamp",
        attributes: %{
          description: "Gradient boosted trees",
          updated_at: ~N[2026-10-20 14:32:00],
          timezone: "Europe/Amsterdam",
          github_commit_url:
            "https://github.com/eyra/fertility-prediction-challenge/commit/3f2a9c1"
        }
      },
      %Variation{
        id: :without_timezone,
        description: "Without timezone the timestamp is hidden",
        attributes: %{
          description: "Gradient boosted trees",
          updated_at: nil,
          timezone: nil,
          github_commit_url:
            "https://github.com/eyra/fertility-prediction-challenge/commit/3f2a9c1"
        }
      }
    ]
  end
end
