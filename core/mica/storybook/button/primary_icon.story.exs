defmodule Storybook.Frameworks.Pixel.Button.PrimaryIcon do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.primary_icon/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          label: "Export",
          to: "/project",
          icon: "/images/icons/export.svg",
          bg_color: "bg-primary"
        },
        slots: []
      }
    ]
  end
end
