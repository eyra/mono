defmodule Storybook.Frameworks.Pixel.Form.Input do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{type: "text", form: form(%{}), field: :code, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          type: "text",
          form: form(%{"code" => "ABC-123"}),
          field: :code,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          type: "text",
          form: form(%{}),
          field: :code,
          label_text: "Access code",
          placeholder: "e.g. ABC-123"
        }
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          type: "text",
          form: form(%{"code" => "ABC-123"}),
          field: :code,
          label_text: "Access code",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          type: "text",
          form: form(%{"code" => ""}, errors: [code: {"is invalid", []}]),
          field: :code,
          label_text: "Access code"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
