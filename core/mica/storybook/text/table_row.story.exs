defmodule Storybook.Frameworks.Pixel.Text.TableRow do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.table_row/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Completed on 12 March 2026"]
      }
    ]
  end
end
