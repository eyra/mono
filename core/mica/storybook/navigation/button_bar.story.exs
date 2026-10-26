defmodule Storybook.Frameworks.Pixel.Navigation.ButtonBar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.button_bar/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Horizontal row of buttons",
        attributes: %{
          buttons: [
            %{action: %{type: :send, event: "save"}, face: %{type: :primary, label: "Save"}},
            %{
              action: %{type: :send, event: "preview"},
              face: %{type: :secondary, label: "Preview"}
            },
            %{action: %{type: :send, event: "cancel"}, face: %{type: :label, label: "Cancel"}}
          ]
        }
      }
    ]
  end
end
