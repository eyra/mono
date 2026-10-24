defmodule Storybook.Frameworks.Pixel.Form.DropdownOption do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.dropdown_option/1

  def variations do
    [
      %Variation{
        id: :unselected,
        description: "Option that is not the current value",
        attributes: %{
          option: %{id: :instagram, value: "Instagram"},
          field_value: "TikTok",
          options_id: "study_platform-options",
          target: nil
        }
      },
      %Variation{
        id: :selected,
        description: "Option matching the current value",
        attributes: %{
          option: %{id: :tiktok, value: "TikTok"},
          field_value: "TikTok",
          options_id: "study_platform-options",
          target: nil
        }
      }
    ]
  end
end
