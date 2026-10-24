defmodule Storybook.Frameworks.Pixel.Paginator.NextPageButton do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Paginator.next_page_button/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{page_count: 1, active_page: 1},
        slots: []
      }
    ]
  end
end
