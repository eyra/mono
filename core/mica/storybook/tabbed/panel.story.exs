defmodule Storybook.Frameworks.Pixel.Tabbed.Panel do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.panel/1

  # Panels and footer items stay hidden until the TabBar hook activates a tab, so a real bar is rendered above.
  def template do
    """
    <div class="flex flex-col gap-6" psb-code-hidden>
      <Frameworks.Pixel.Tabbed.bar id="panel_bar" initial_tab="workflow" tabs={Storybook.Frameworks.Pixel.Tabbed.Panel.tabs()} />
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Panel of the Workflow tab; visible because Workflow is the active tab",
        attributes: %{bar_id: "panel_bar", tab_id: "workflow"},
        slots: [
          """
          <Frameworks.Pixel.Text.body_large>
            Add the tasks participants complete, in order: consent, questionnaire, data donation.
          </Frameworks.Pixel.Text.body_large>
          """
        ]
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
