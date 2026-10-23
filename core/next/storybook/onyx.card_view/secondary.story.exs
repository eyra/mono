defmodule Storybook.Systems.Onyx.CardView.Secondary do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Onyx.CardView.secondary/1

  def template do
    """
    <div class="w-96"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :concept,
        description: "Concept",
        attributes: %{
          card: %{
            type: :secondary,
            id: "secondary-concept-1",
            title: "Screen time",
            tags: ["Concept"],
            info: "Created yesterday at 14:32 by Jane Doe"
          }
        }
      },
      %Variation{
        id: :predicate,
        description: "Predicate",
        attributes: %{
          card: %{
            type: :secondary,
            id: "secondary-predicate-2",
            title: "Screen time > Sleep quality",
            tags: ["Predicate"],
            info: "Created Monday at 09:15 by Jane Doe"
          }
        }
      },
      %Variation{
        id: :annotation,
        description: "Annotation with reference tags",
        attributes: %{
          card: %{
            type: :secondary,
            id: "secondary-annotation-3",
            title: "Evening smartphone use delays sleep onset in adolescents",
            tags: ["Annotation", "Finding", "Smith et al. 2021"],
            info: "Created 12 October at 10:04 by John Smith"
          }
        }
      }
    ]
  end
end
