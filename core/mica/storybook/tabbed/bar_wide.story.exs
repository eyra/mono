defmodule Storybook.Frameworks.Pixel.Tabbed.BarWide do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.bar_wide/1

  # The TabBar JS hook marks the initial tab active (tabs are idle until a TabBar mounts).
  def template do
    """
    <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :seperated,
        description: "Numbered tabs with a gap",
        attributes: %{id: "bar_wide_seperated", tabs: tabs()}
      },
      %Variation{
        id: :segmented,
        description: "Segmented tabs (shown here inside the pill shape the bar adds)",
        attributes: %{id: "bar_wide_segmented", type: :segmented, tabs: tabs()},
        template: """
        <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="rounded-full overflow-hidden h-10 bg-grey5 inline-block" psb-code-hidden>
          <.psb-variation/>
        </div>
        """
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
