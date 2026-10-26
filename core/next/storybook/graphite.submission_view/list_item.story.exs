defmodule Storybook.Systems.Graphite.SubmissionView.ListItem do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Graphite.SubmissionView.list_item/1

  def template do
    """
    <table><tbody><.psb-variation/></tbody></table>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Submission row with team",
        attributes: %{
          team: "Team Tilburg",
          description: "Gradient boosted trees",
          summary: "Submitted yesterday at 14:32",
          url: "https://example.org/fertility-prediction-challenge/commit/3f2a9c1",
          buttons: []
        }
      },
      %Variation{
        id: :with_buttons,
        description: "Own submission without team, with edit and remove buttons",
        attributes: %{
          description: "Logistic regression",
          summary: "Submitted Monday at 09:15",
          url: "https://example.org/fertility-prediction-challenge/commit/b71e04d",
          buttons: [
            %{action: %{type: :send, event: "edit"}, face: %{type: :icon, icon: :edit}},
            %{action: %{type: :send, event: "remove"}, face: %{type: :icon, icon: :delete}}
          ]
        }
      }
    ]
  end
end
