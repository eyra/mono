defmodule Storybook.Frameworks.Pixel.Text.FormFieldLabel do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.form_field_label/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "email-label"},
        slots: ["Email address"]
      }
    ]
  end
end
