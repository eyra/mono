defmodule Storybook.Frameworks.Pixel.Form.PasswordInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.password_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :password, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{
          form: form(%{"password" => "correct horse battery"}),
          field: :password,
          label_text: nil
        }
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :password, label_text: "Password"}
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form:
            form(%{"password" => ""},
              errors: [password: {"should be at least 12 character(s)", []}]
            ),
          field: :password,
          label_text: "Password"
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
