defmodule Storybook.Systems.Onyx.CardView.Basic do
  use PhoenixStorybook.Story, :component

  def function, do: &Systems.Onyx.CardView.basic/1

  def template do
    """
    <div class="w-96"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Primary knowledge card",
        attributes: %{
          id: "concept-1",
          title: "Screen time",
          tags: ["Concept"],
          info: "Created yesterday at 14:32 by Jane Doe"
        }
      },
      %Variation{
        id: :many_tags,
        description: "Tags beyond tag_limit (3) are hidden",
        attributes: %{
          id: "annotation-3",
          title: "Evening smartphone use delays sleep onset",
          tags: ["Annotation", "Finding", "Smith et al. 2021", "Hidden tag"],
          info: "Created 12 October at 10:04 by John Smith"
        }
      },
      %Variation{
        id: :row,
        description: "Row layout, single tag, no info",
        attributes: %{
          id: "predicate-2",
          title: "Screen time > Sleep quality",
          tags: ["Predicate"],
          info_visible: false,
          flex_direction: "flex-row",
          tag_limit: 1,
          bg_color: "grey5",
          text_color: "text-grey1",
          tag_type: "primary"
        }
      }
    ]
  end
end
