defmodule Storybook.Frameworks.Pixel.Card.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Card.button/1

  def template do
    """
    <div class="w-96 h-80"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Dashed call-to-action card for creating a new item",
        attributes: %{
          title: "Create a new study",
          image: "/images/plus-primary.svg",
          event: "create_study"
        }
      }
    ]
  end
end
