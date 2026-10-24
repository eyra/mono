defmodule Storybook.Frameworks.Pixel.Text.TableHead do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.table_head/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["Participant"]
      }
    ]
  end
end
