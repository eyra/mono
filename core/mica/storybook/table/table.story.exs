defmodule Storybook.Frameworks.Pixel.Table.Table do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.table/1

  # Tables fill their parent; one column gives them a realistic width.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :bordered,
        description:
          "Head row and 3 rows mixing text, tag and date cells, inside a rounded border",
        attributes: %{
          id: "assignments",
          layout: columns(),
          head_cells: head_cells(),
          rows: rows()
        }
      },
      %Variation{
        id: :borderless,
        description: "border={false} with top_line?, as used for the payouts overview",
        attributes: %{
          id: "assignments-borderless",
          layout: columns(),
          head_cells: head_cells(),
          rows: rows(),
          border: false,
          top_line?: true
        }
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

  defp head_cells, do: ["Assignment", "Participants", "Status", "Last change"]

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
