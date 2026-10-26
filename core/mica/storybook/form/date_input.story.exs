defmodule Storybook.Frameworks.Pixel.Form.DateInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.date_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :start_date, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"start_date" => "2026-11-01"}),
          field: :start_date,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :start_date, label_text: "Start date"}
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          form: form(%{"start_date" => "2026-11-01"}),
          field: :start_date,
          label_text: "Start date",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"start_date" => ""}, errors: [start_date: {"can't be blank", []}]),
          field: :start_date,
          label_text: "Start date"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
