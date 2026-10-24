defmodule Storybook.Frameworks.Pixel.Table.Content do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.content/1

  # Full width so the :text_truncate cell has a width to truncate against.
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :text,
        description: "Plain value",
        attributes: %{type: :text, value: "Screen time diary"}
      },
      %Variation{
        id: :text_truncate,
        description: "Truncated with an ellipsis",
        attributes: %{
          type: :text_truncate,
          value: "Screen time diary: a two-week experience sampling study on smartphone use"
        }
      },
      %Variation{
        id: :tag,
        description: "Coloured tag",
        attributes: %{
          type: :tag,
          value: %{text: "Online", bg_color: "bg-success", text_color: "text-success"}
        }
      },
      %Variation{
        id: :date,
        description: "Formatted DateTime",
        attributes: %{type: :date, value: ~U[2026-10-21 14:30:00Z]}
      },
      %Variation{
        id: :href,
        description: "External link",
        attributes: %{type: :href, value: "https://example.org/survey/screen-time"}
      },
      %Variation{
        id: :action,
        description: "Button",
        attributes: %{
          type: :action,
          value: %{
            action: %{type: :send, event: "remove", item: "42"},
            face: %{type: :label, label: "Remove"}
          }
        }
      },
      %Variation{
        id: :spinner,
        description: "Static spinner",
        attributes: %{type: :action, value: :spinner_static}
      }
    ]
  end
end
