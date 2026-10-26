defmodule Storybook.Frameworks.Pixel.Card.Label do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Card.label/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Status label shown on top of a card",
        attributes: %{text: "Open"}
      },
      %VariationGroup{
        id: :types,
        description: "All label types",
        template: """
        <div class="flex flex-col gap-4"><.psb-variation-group/></div>
        """,
        variations: [
          %Variation{
            id: :primary,
            description: ":primary",
            attributes: %{text: "Open", type: :primary}
          },
          %Variation{
            id: :secondary,
            description: ":secondary",
            attributes: %{text: "Concept", type: :secondary}
          },
          %Variation{
            id: :tertiary,
            description: ":tertiary",
            attributes: %{text: "Draft", type: :tertiary}
          },
          %Variation{
            id: :success,
            description: ":success",
            attributes: %{text: "Finished", type: :success}
          },
          %Variation{
            id: :warning,
            description: ":warning",
            attributes: %{text: "Closing soon", type: :warning}
          },
          %Variation{
            id: :delete,
            description: ":delete",
            attributes: %{text: "Closed", type: :delete}
          },
          %Variation{
            id: :disabled,
            description: ":disabled",
            attributes: %{text: "Archived", type: :disabled}
          },
          %Variation{
            id: :idle,
            description: ":idle",
            attributes: %{text: "Scheduled", type: :idle}
          }
        ]
      }
    ]
  end
end
