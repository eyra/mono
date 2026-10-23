defmodule Storybook.Frameworks.Pixel.Form.TextArea do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.text_area/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :description, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form:
            form(%{
              "description" =>
                "Participants answer a short questionnaire about their daily phone use."
            }),
          field: :description,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          form: form(%{}),
          field: :description,
          label_text: "Description",
          placeholder: "Describe your study"
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"description" => ""}, errors: [description: {"can't be blank", []}]),
          field: :description,
          label_text: "Description"
        }
      },
      %Variation{
        id: :short,
        description: "Reduced height",
        attributes: %{
          form: form(%{"description" => "A short note."}),
          field: :description,
          label_text: "Note",
          height: "h-24"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
