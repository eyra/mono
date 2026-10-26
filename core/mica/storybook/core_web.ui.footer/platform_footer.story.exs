defmodule Storybook.CoreWeb.UI.Footer.PlatformFooter do
  use PhoenixStorybook.Story, :component

  def function, do: &CoreWeb.UI.Footer.platform_footer/1

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
