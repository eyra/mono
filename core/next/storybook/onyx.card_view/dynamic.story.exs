defmodule Storybook.Systems.Onyx.CardView.Dynamic do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Onyx.CardView.dynamic/1

  def template do
    """
    <div class="w-96"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :types,
        description: "Card type selects primary, secondary or tertiary rendering",
        variations: [
          %Variation{
            id: :primary,
            description: ":primary",
            attributes: %{
              card: %{
                type: :primary,
                id: "primary-concept-1",
                title: "Screen time",
                tags: ["Concept"],
                info: "Created yesterday at 14:32 by Jane Doe"
              }
            }
          },
          %Variation{
            id: :secondary,
            description: ":secondary",
            attributes: %{
              card: %{
                type: :secondary,
                id: "secondary-annotation-3",
                title: "Evening smartphone use delays sleep onset in adolescents",
                tags: ["Annotation", "Finding", "Smith et al. 2021"],
                info: "Created 12 October at 10:04 by John Smith"
              }
            }
          },
          %Variation{
            id: :tertiary,
            description: ":tertiary (history list)",
            attributes: %{
              card: %{
                type: :tertiary,
                id: "tertiary-predicate-2",
                title: "Screen time > Sleep quality",
                tags: ["Predicate"],
                info: "Created Monday at 09:15 by Jane Doe"
              }
            }
          }
        ]
      }
    ]
  end
end
