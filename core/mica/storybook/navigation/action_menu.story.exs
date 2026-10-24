defmodule Storybook.Frameworks.Pixel.Navigation.ActionMenu do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.action_menu/1

  def variations do
    [
      %Variation{
        id: :default,
        description:
          "Dropdown of the action bar's more-menu; renders the :label button of each entry",
        attributes: %{
          buttons: [
            %{label: button(:duplicate, "Duplicate")},
            %{label: button(:export, "Export participants")},
            %{label: button(:archive, "Archive")}
          ]
        }
      }
    ]
  end

  defp button(item, label) do
    %{
      action: %{type: :send, event: "action_click", item: item},
      face: %{type: :label, label: label}
    }
  end
end
