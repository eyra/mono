defmodule Storybook.Frameworks.Pixel.Form.RadioGroup do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.radio_group/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "One option active",
        attributes: %{form: form(), field: :language, label_text: "Language", items: items()}
      },
      %Variation{
        id: :with_subtitle,
        description: "With subtitle",
        attributes: %{
          form: form(),
          field: :language,
          label_text: "Language",
          label_subtitle: "Participants see the study in this language",
          items: items()
        }
      },
      %Variation{
        id: :with_disabled_item,
        description: "One option disabled",
        attributes: %{
          form: form(),
          field: :language,
          label_text: "Language",
          items: items() ++ [%{id: :de, value: "German", active: false, disabled: true}]
        }
      }
    ]
  end

  defp form, do: Phoenix.Component.to_form(%{"language" => "en"}, as: :study)

  defp items do
    [
      %{id: :en, value: "English", active: true},
      %{id: :nl, value: "Dutch", active: false}
    ]
  end
end
