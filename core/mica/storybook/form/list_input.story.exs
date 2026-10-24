defmodule Storybook.Frameworks.Pixel.Form.ListInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.list_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :keywords, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"keywords" => "privacy, wellbeing"}),
          field: :keywords,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          form: form(%{}),
          field: :keywords,
          label_text: "Keywords",
          placeholder: "Comma separated keywords"
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"keywords" => ""}, errors: [keywords: {"can't be blank", []}]),
          field: :keywords,
          label_text: "Keywords"
        }
      },
      %Variation{
        id: :forced_value,
        description: "Forced display value",
        attributes: %{
          form: form(%{}),
          field: :keywords,
          label_text: "Keywords",
          value: "privacy, wellbeing, social media"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
