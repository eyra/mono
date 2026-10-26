defmodule Storybook.Frameworks.Pixel.Square.Item do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Square.item/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "Questionnaire",
          subtitle: "3 questions",
          icon: {:static, "projects"},
          action: %{type: :send, event: "select", item: "1"}
        }
      },
      %Variation{
        id: :active,
        attributes: %{
          title: "Data donation",
          subtitle: "Ready",
          state: {:active, :success},
          action: %{type: :send, event: "select", item: "2"}
        }
      },
      %Variation{
        id: :transparent,
        attributes: %{
          title: "Add item",
          state: :transparent,
          action: %{type: :send, event: "add"}
        }
      }
    ]
  end
end
