defmodule Storybook.Frameworks.Pixel.Panel.Usp do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Panel.usp/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Unique selling point",
        attributes: %{
          title: "Recruit participants",
          description:
            "Reach thousands of registered participants and fill your study in days, not weeks."
        }
      },
      %VariationGroup{
        id: :usps,
        description: "Row of USPs",
        template: """
        <div class="grid grid-cols-3 gap-4"><.psb-variation-group/></div>
        """,
        variations: [
          %Variation{
            id: :recruit,
            attributes: %{
              title: "Recruit participants",
              description:
                "Reach thousands of registered participants and fill your study in days."
            }
          },
          %Variation{
            id: :privacy,
            attributes: %{
              title: "Privacy by design",
              description:
                "Data donations stay under the control of the participant until they consent."
            }
          },
          %Variation{
            id: :primary_title,
            description: "title_color text-primary",
            attributes: %{
              title: "Open science",
              description: "Share materials and data with other researchers in one click.",
              title_color: "text-primary"
            }
          }
        ]
      }
    ]
  end
end
