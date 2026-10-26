defmodule Storybook.Frameworks.Pixel.Paginator.PreviousPageButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Paginator.previous_page_button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{active_page: 1},
        slots: []
      }
    ]
  end
end
