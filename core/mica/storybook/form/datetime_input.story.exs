defmodule Storybook.Frameworks.Pixel.Form.DatetimeInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.datetime_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :starts_at, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"starts_at" => "2026-11-01T09:00"}),
          field: :starts_at,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :starts_at, label_text: "Starts at"}
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          form: form(%{"starts_at" => "2026-11-01T09:00"}),
          field: :starts_at,
          label_text: "Starts at",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"starts_at" => ""}, errors: [starts_at: {"can't be blank", []}]),
          field: :starts_at,
          label_text: "Starts at"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
