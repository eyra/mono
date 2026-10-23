defmodule Storybook.Frameworks.Pixel.Paginator.PageButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Paginator.page_button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{index: 1, active?: false},
        slots: []
      }
    ]
  end
end
