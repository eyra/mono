defmodule Storybook.Frameworks.Pixel.Tabbed.Bar do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.bar/1

  def variations do
    [
      %Variation{
        id: :seperated,
        description:
          "Default: numbered tabs (:seperated, :wide); falls back to the narrow dropdown when it does not fit. Workflow is active.",
        attributes: %{id: "bar_seperated", initial_tab: "workflow", tabs: tabs()}
      },
      %Variation{
        id: :segmented,
        description: "Segmented pill (:segmented, :wide)",
        attributes: %{
          id: "bar_segmented",
          type: :segmented,
          initial_tab: "workflow",
          tabs: tabs()
        }
      },
      %Variation{
        id: :segmented_full,
        description: "Segmented pill stretched to the full width (:segmented, :full)",
        attributes: %{
          id: "bar_full",
          type: :segmented,
          size: :full,
          initial_tab: "workflow",
          tabs: tabs()
        }
      }
    ]
  end

  def tabs do
    [
      %{id: "settings", title: "Settings", forward_title: "Go to Settings", type: :fullpage},
      %{id: "workflow", title: "Workflow", forward_title: "Go to Workflow", type: :fullpage},
      %{id: "monitor", title: "Monitor", forward_title: "Go to Monitor", type: :fullpage}
    ]
  end
end
