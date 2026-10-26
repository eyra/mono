defmodule Storybook.Frameworks.Pixel.Button.Face do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.face/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{type: :primary, label: "Save"}
      },
      %Variation{
        id: :icon,
        attributes: %{type: :icon, icon: :edit}
      }
    ]
  end
end
