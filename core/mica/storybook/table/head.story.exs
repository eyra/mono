defmodule Storybook.Frameworks.Pixel.Table.Head do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.head/1

  # Tables fill their parent; one column gives them a realistic width.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def template do
    """
    <div class="border-[2px] border-grey4 rounded-lg overflow-hidden w-full" psb-code-hidden>
      <table class="w-full table-fixed">
        <.psb-variation/>
      </table>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Table head: one head cell per column, widths and alignment from the layout",
        attributes: %{cells: head_cells(), layout: columns()}
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
end
