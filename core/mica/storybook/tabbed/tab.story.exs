defmodule Storybook.Frameworks.Pixel.Tabbed.Tab do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.tab/1

  def variations do
    [
      %Variation{
        id: :active,
        description: "Numbered tab, activated by a TabBar hook",
        attributes: %{
          id: "workflow",
          bar_id: "tab_story",
          size: "wide",
          index: 1,
          title: "Workflow"
        },
        template: """
        <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="inline-block" psb-code-hidden>
          <.psb-variation/>
        </div>
        """
      },
      %Variation{
        id: :idle,
        description: "Idle numbered tab",
        attributes: %{
          id: "settings",
          bar_id: "tab_story",
          size: "wide",
          index: 0,
          title: "Settings"
        }
      },
      %Variation{
        id: :with_count,
        description: "The count replaces the tab number",
        attributes: %{
          id: "participants",
          bar_id: "tab_story",
          size: "wide",
          index: 2,
          count: 12,
          title: "Participants"
        }
      },
      %Variation{
        id: :with_errors,
        description: "Not ready and show_errors: warning colour and an exclamation mark",
        attributes: %{
          id: "criteria",
          bar_id: "tab_story",
          size: "wide",
          index: 3,
          ready: false,
          show_errors: true,
          title: "Criteria"
        }
      },
      %Variation{
        id: :segmented,
        description: "Segmented tab (no number)",
        attributes: %{
          id: "monitor",
          bar_id: "tab_story",
          size: "wide",
          type: :segmented,
          title: "Monitor"
        },
        template: """
        <div class="rounded-full overflow-hidden h-10 bg-grey5 inline-block" psb-code-hidden>
          <.psb-variation/>
        </div>
        """
      }
    ]
  end
end
