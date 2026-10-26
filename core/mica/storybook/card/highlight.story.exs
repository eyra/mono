defmodule Storybook.Frameworks.Pixel.Card.Highlight do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Card.highlight/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Key fact of a study",
        attributes: %{title: "Reward", text: "€ 7,50"}
      },
      %VariationGroup{
        id: :study_facts,
        description: "Typical study highlights",
        template: """
        <div class="grid grid-cols-3 gap-4"><.psb-variation-group/></div>
        """,
        variations: [
          %Variation{id: :duration, attributes: %{title: "Duration", text: "15 minutes"}},
          %Variation{id: :reward, attributes: %{title: "Reward", text: "€ 7,50"}},
          %Variation{id: :spots, attributes: %{title: "Spots left", text: "42 of 200"}}
        ]
      }
    ]
  end
end
