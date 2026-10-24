defmodule Storybook.Frameworks.Pixel.Panel.Flat do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Panel.flat/1

  @title ~s|<:title><div class="text-title5 font-title5 mb-4">About this study</div></:title>|
  @body ~s|<div class="text-bodymedium font-body text-grey2">Researchers at the university want to learn how screen time affects sleep quality. Your data is stored anonymously.</div>|

  def variations do
    [
      %Variation{
        id: :default,
        description: "Panel with title and body",
        slots: [@title, @body]
      },
      %Variation{
        id: :without_title,
        description: "Panel without title",
        slots: [@body]
      },
      %VariationGroup{
        id: :bg_colors,
        description: "Background colors",
        template: """
        <div class="grid grid-cols-3 gap-4"><.psb-variation-group/></div>
        """,
        variations:
          for bg <- ~w(bg-grey6 bg-grey5 bg-white) do
            %Variation{
              id: String.to_atom(bg),
              description: bg,
              attributes: %{bg_color: bg},
              slots: [@title, @body]
            }
          end
      },
      %VariationGroup{
        id: :alignment_and_padding,
        description: "Alignment and padding",
        variations: [
          %Variation{
            id: :centered,
            description: "text-center",
            attributes: %{align: "text-center"},
            slots: [@title, @body]
          },
          %Variation{
            id: :compact,
            description: "padding p-4",
            attributes: %{padding: "p-4"},
            slots: [@title, @body]
          }
        ]
      }
    ]
  end
end
