defmodule Storybook.Frameworks.Pixel.Button.DynamicBar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Button.dynamic_bar/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Form footer with submit, cancel and help link",
        attributes: %{
          buttons: [
            %{
              action: %{type: :send, event: "save"},
              face: %{type: :primary, label: "Save"}
            },
            %{
              action: %{type: :send, event: "cancel"},
              face: %{type: :label, label: "Cancel"}
            },
            %{
              action: %{type: :http_get, to: "https://example.org", target: "_blank"},
              face: %{type: :plain, label: "Help", icon: :forward}
            }
          ]
        }
      }
    ]
  end
end
