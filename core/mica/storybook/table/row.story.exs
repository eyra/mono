defmodule Storybook.Frameworks.Pixel.Table.Row do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.row/1

  # Tables fill their parent; one column gives them a realistic width.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def template do
    """
    <div class="border-[2px] border-grey4 rounded-lg overflow-hidden w-full" psb-code-hidden>
      <table class="w-full table-fixed">
        <tbody><.psb-variation/></tbody>
      </table>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :first,
        description: "First row (top padding, no top line)",
        attributes: %{cells: Enum.at(rows(), 0), layout: columns(), top: true}
      },
      %Variation{
        id: :middle,
        description: "Following rows get a top line",
        attributes: %{cells: Enum.at(rows(), 1), layout: columns()}
      },
      %Variation{
        id: :last,
        description: "Last row",
        attributes: %{cells: Enum.at(rows(), 2), layout: columns(), bottom: true}
      }
    ]
  end

  defp columns do
    [
      %{type: :text, width: "w-2/5", align: "text-left"},
      %{type: :text, width: "w-1/6", align: "text-center"},
      %{type: :tag, width: "w-1/6", align: "text-left"},
      %{type: :date, width: "w-1/4", align: "text-right"}
    ]
  end

  defp rows do
    [
      [
        "Social media use and wellbeing",
        128,
        tag("Online", "bg-success", "text-success"),
        ~U[2026-10-21 14:30:00Z]
      ],
      [
        "Screen time diary",
        42,
        tag("Concept", "bg-warning", "text-warning"),
        ~U[2026-10-18 09:15:00Z]
      ],
      [
        "Sleep and smartphone habits",
        0,
        tag("Closed", "bg-tertiary", "text-grey1"),
        ~U[2026-09-30 16:45:00Z]
      ]
    ]
  end

  defp tag(text, bg_color, text_color),
    do: %{text: text, bg_color: bg_color, text_color: text_color}
end
