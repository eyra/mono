defmodule MicaWeb.Storybook.UI.Footer.ContentFooter do
  use PhoenixStorybook.Story, :component

  def function, do: &MicaWeb.UI.Footer.content_footer/1

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
