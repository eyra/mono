defmodule Storybook.Frameworks.Pixel.Form.EmailInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.email_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :email, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"email" => "researcher@university.edu"}),
          field: :email,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label and placeholder",
        attributes: %{
          form: form(%{}),
          field: :email,
          label_text: "Email address",
          placeholder: "you@example.com"
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"email" => ""}, errors: [email: {"has invalid format", []}]),
          field: :email,
          label_text: "Email address"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
