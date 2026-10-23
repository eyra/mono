defmodule Storybook.Frameworks.Pixel.Paginator.Paginator do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Paginator.paginator/1

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
