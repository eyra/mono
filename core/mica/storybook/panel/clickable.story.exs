defmodule Storybook.Frameworks.Pixel.Panel.Clickable do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Panel.clickable/1

  @title ~s|<:title><div class="text-title5 font-title5 mb-2">Sleep diary</div></:title>|
  @body ~s|<div class="text-bodysmall font-body text-grey2">7 days · 2 minutes per day · 128 participants</div>|

  def template do
    """
    <div class="w-80"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Clicking sends handle_panel_click with phx-value-item",
        attributes: %{item: "sleep-diary"},
        slots: [@title, @body]
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
              attributes: %{item: "sleep-diary", bg_color: bg},
              slots: [@title, @body]
            }
          end
      },
      %Variation{
        id: :centered,
        description: "Centered content",
        attributes: %{item: "sleep-diary", align: "text-center"},
        slots: [@title, @body]
      }
    ]
  end
end
