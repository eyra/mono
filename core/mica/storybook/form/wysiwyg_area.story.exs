defmodule Storybook.Frameworks.Pixel.Form.WysiwygArea do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.wysiwyg_area/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :body, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"body" => "<p>Welcome to <strong>our study</strong>.</p>"}),
          field: :body,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :body, label_text: "Introduction"}
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"body" => ""}, errors: [body: {"can't be blank", []}]),
          field: :body,
          label_text: "Introduction"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
