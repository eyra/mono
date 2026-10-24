defmodule Storybook.Frameworks.Pixel.Form.TextInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.text_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :title, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"title" => "Screen time and wellbeing"}),
          field: :title,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          form: form(%{}),
          field: :title,
          label_text: "Title",
          placeholder: "Enter a study title"
        }
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          form: form(%{"title" => "Screen time and wellbeing"}),
          field: :title,
          label_text: "Title",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"title" => ""}, errors: [title: {"can't be blank", []}]),
          field: :title,
          label_text: "Title"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
