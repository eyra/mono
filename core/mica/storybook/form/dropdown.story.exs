defmodule Storybook.Frameworks.Pixel.Form.Dropdown do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.dropdown/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Nothing selected",
        attributes: %{
          form: form(%{}),
          field: :platform,
          options: options(),
          target: nil,
          label_text: nil
        }
      },
      %Variation{
        id: :prefilled,
        description: "Option selected",
        attributes: %{
          form: form(%{"platform" => "tiktok"}),
          field: :platform,
          options: options(),
          target: nil,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          form: form(%{}),
          field: :platform,
          options: options(),
          target: nil,
          label_text: "Platform",
          placeholder: "Select a platform"
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"platform" => ""}, errors: [platform: {"can't be blank", []}]),
          field: :platform,
          options: options(),
          target: nil,
          label_text: "Platform",
          placeholder: "Select a platform"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)

  defp options do
    [
      %{id: :instagram, value: "Instagram"},
      %{id: :tiktok, value: "TikTok"},
      %{id: :youtube, value: "YouTube"},
      %{id: :whatsapp, value: "WhatsApp"}
    ]
  end
end
