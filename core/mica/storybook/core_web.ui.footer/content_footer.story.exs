defmodule Storybook.CoreWeb.UI.Footer.ContentFooter do
  use PhoenixStorybook.Story, :component

  def function, do: &CoreWeb.UI.Footer.content_footer/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: []
      }
    ]
  end
end
