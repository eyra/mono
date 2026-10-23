defmodule Storybook.Frameworks.Pixel.Tabbed.Dropdown do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.dropdown/1

  # The TabBar JS hook marks the initial tab active (tabs are idle until a TabBar mounts).
  def template do
    """
    <div id="tabbar-:variation_id" phx-hook="TabBar" data-initial-tab="workflow" class="inline-block" psb-code-hidden>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Dropdown listing all tabs, opened from the narrow bar",
        attributes: %{bar_id: "bar_dropdown", tabs: tabs()}
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
