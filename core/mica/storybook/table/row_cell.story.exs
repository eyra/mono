defmodule Storybook.Frameworks.Pixel.Table.RowCell do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Table.row_cell/1

  # Tables fill their parent; one column gives them a realistic width.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def template do
    """
    <div class="border-[2px] border-grey4 rounded-lg overflow-hidden w-full" psb-code-hidden>
      <table class="w-full table-fixed"><tbody><tr class="h-12"><.psb-variation-group/></tr></tbody></table>
    </div>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :text_tag_date,
        description:
          "A table row: text, centred number, tag and date cells (left/right cells get border padding)",
        variations: [
          %Variation{
            id: :assignment,
            attributes: %{
              content: "Social media use and wellbeing",
              layout: %{type: :text, align: "text-left"},
              left: true,
              top: true
            }
          },
          %Variation{
            id: :participants,
            attributes: %{content: 128, layout: %{type: :text, align: "text-center"}, top: true}
          },
          %Variation{
            id: :status,
            attributes: %{
              content: %{text: "Online", bg_color: "bg-success", text_color: "text-success"},
              layout: %{type: :tag, align: "text-left"},
              top: true
            }
          },
          %Variation{
            id: :last_change,
            attributes: %{
              content: ~U[2026-10-21 14:30:00Z],
              layout: %{type: :date, align: "text-right"},
              right: true,
              top: true
            }
          }
        ]
      },
      %VariationGroup{
        id: :links_and_actions,
        description: "Link, truncated text and action button cells",
        variations: [
          %Variation{
            id: :href,
            attributes: %{
              content: "https://example.org/survey/screen-time",
              layout: %{type: :href, align: "text-left"},
              left: true
            }
          },
          %Variation{
            id: :invalid_href,
            attributes: %{content: "not a url", layout: %{type: :href, align: "text-left"}}
          },
          %Variation{
            id: :truncate,
            attributes: %{
              content:
                "Screen time diary: a two-week experience sampling study on smartphone use",
              layout: %{type: :text_truncate, align: "text-left"}
            }
          },
          %Variation{
            id: :action,
            attributes: %{
              content: %{
                action: %{type: :send, event: "remove", item: "42"},
                face: %{type: :label, label: "Remove", text_color: "text-error"}
              },
              layout: %{type: :action, align: "text-right"},
              right: true
            }
          }
        ]
      }
    ]
  end
end
