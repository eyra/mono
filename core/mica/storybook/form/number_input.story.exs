defmodule Storybook.Frameworks.Pixel.Form.NumberInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.number_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :duration, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{form: form(%{"duration" => "15"}), field: :duration, label_text: nil}
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :duration, label_text: "Duration (minutes)"}
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          form: form(%{"duration" => "15"}),
          field: :duration,
          label_text: "Duration (minutes)",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"duration" => ""}, errors: [duration: {"must be greater than 0", []}]),
          field: :duration,
          label_text: "Duration (minutes)"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
