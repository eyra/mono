defmodule Storybook.Frameworks.Pixel.Tabbed.BarNarrow do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.bar_narrow/1

  def container, do: {:div, class: "h-[280px]"}

  # The TabBar JS hook marks the initial tab active (tabs are idle until a TabBar mounts).
  def template do
    """
    <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="relative h-[72px] flex items-center" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Only the active tab is shown; click it to open the dropdown with all tabs",
        attributes: %{id: "bar_narrow", tabs: tabs()}
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
