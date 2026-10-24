defmodule Storybook.Frameworks.Pixel.Selector.Item.Radio do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Selector.Item.radio/1

  def variations do
    [
      %Variation{
        id: :unselected,
        description: "Unselected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: false}}
      },
      %Variation{
        id: :selected,
        description: "Selected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: true}}
      },
      %Variation{
        id: :dark_selected,
        description: "Selected on dark background",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: true}, background: :dark},
        template: ~s(<div class="bg-grey1 p-4"><.psb-variation/></div>)
      },
      %Variation{
        id: :dark_unselected,
        description: "Unselected on dark background",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: false}, background: :dark},
        template: ~s(<div class="bg-grey1 p-4"><.psb-variation/></div>)
      }
    ]
  end
end
