defmodule Storybook.Frameworks.Pixel.Table.HeadCell do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.head_cell/1

  # Tables fill their parent; one column gives them a realistic width.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %VariationGroup{
        id: :head_row,
        description: "Four head cells forming the head of an assignments table",
        template: """
        <div class="border-[2px] border-grey4 rounded-lg overflow-hidden w-full" psb-code-hidden>
          <table class="w-full table-fixed"><thead><tr><.psb-variation-group/></tr></thead></table>
        </div>
        """,
        variations: [
          %Variation{
            id: :assignment,
            attributes: %{content: "Assignment", layout: %{width: "w-2/5", align: "text-left"}}
          },
          %Variation{
            id: :participants,
            attributes: %{
              content: "Participants",
              layout: %{width: "w-1/6", align: "text-center"}
            }
          },
          %Variation{
            id: :status,
            attributes: %{content: "Status", layout: %{width: "w-1/6", align: "text-left"}}
          },
          %Variation{
            id: :last_change,
            attributes: %{content: "Last change", layout: %{width: "w-1/4", align: "text-right"}}
          }
        ]
      }
    ]
  end
end
