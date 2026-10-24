defmodule Storybook.Frameworks.Pixel.Tabbed.BarFull do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.bar_full/1

  # The TabBar JS hook marks the initial tab active; the wrapper adds the pill shape bar/1 uses.
  def template do
    """
    <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="rounded-full overflow-hidden h-10 w-full bg-grey5" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :segmented,
        description: "Equal-width segmented tabs filling the row",
        attributes: %{id: "bar_full_segmented", type: :segmented, tabs: tabs()}
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
