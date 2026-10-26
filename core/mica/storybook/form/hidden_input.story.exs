defmodule Storybook.Frameworks.Pixel.Form.HiddenInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.hidden_input/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Hidden field carrying the study id (renders no visible output)",
        attributes: %{form: Phoenix.Component.to_form(%{"id" => "42"}, as: :study), field: :id}
      }
    ]
  end
end
