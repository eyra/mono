defmodule Storybook.Frameworks.Pixel.Navigation.ActionBar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Navigation.action_bar/1

  # Full-width bar: one column and a full-width container keep it inside the variation box.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :content_page,
        description:
          "Breadcrumbs, a tab bar in the slot, right-bar buttons (icon on mobile, label from md) and a more-menu",
        attributes: %{
          breadcrumbs: [
            %{label: "Projects", path: "/project"},
            %{label: "Social media use and wellbeing", path: "/project/node/1"},
            %{label: "Data donation", path: nil}
          ],
          right_bar_buttons: [
            %{
              label: %{
                action: %{type: :send, event: "action_click", item: :preview},
                face: %{type: :secondary, label: "Preview"}
              },
              icon: %{
                action: %{type: :send, event: "action_click", item: :preview},
                face: %{type: :icon, icon: :preview, alt: "Preview"}
              }
            },
            %{
              action: %{type: :send, event: "action_click", item: :publish},
              face: %{type: :primary, label: "Publish", bg_color: "bg-success"}
            }
          ],
          more_buttons: [
            %{
              label: %{
                action: %{type: :send, event: "action_click", item: :duplicate},
                face: %{type: :label, label: "Duplicate"}
              }
            },
            %{
              label: %{
                action: %{type: :send, event: "action_click", item: :delete},
                face: %{type: :label, label: "Delete", text_color: "text-error"}
              }
            }
          ]
        },
        slots: [
          """
          <Frameworks.Pixel.Tabbed.bar
            id="action_bar_tabs"
            type={:segmented}
            initial_tab="settings"
            tabs={[
              %{id: "settings", title: "Settings"},
              %{id: "workflow", title: "Workflow"},
              %{id: "monitor", title: "Monitor"}
            ]}
          />
          """
        ]
      },
      %Variation{
        id: :centered,
        description: "Centred, without breadcrumbs, as used by adaptable pages",
        attributes: %{
          breadcrumbs: [],
          align: :center,
          right_bar_buttons: [
            %{
              action: %{type: :send, event: "save"},
              face: %{type: :primary, label: "Save"}
            }
          ]
        },
        slots: [
          """
          <div class="font-title7 text-title7">Edit questionnaire</div>
          """
        ]
      }
    ]
  end
end
