defmodule Storybook.Frameworks.Pixel.Tabbed.Footer do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.footer/1

  # Page-level footer: full width, like below a content page.
  def container, do: {:div, class: "w-full"}

  def layout, do: :one_column

  # Panels and footer items stay hidden until the TabBar hook activates a tab, so a real bar is rendered above.
  def template do
    """
    <div class="flex flex-col gap-6" psb-code-hidden>
      <Frameworks.Pixel.Tabbed.bar id="footer_bar" initial_tab="workflow" tabs={Storybook.Frameworks.Pixel.Tabbed.Footer.tabs()} />
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description:
          "Forward link to the next tab (its :forward_title), shown for the active tab: on Workflow it reads Go to Monitor",
        attributes: %{bar_id: "footer_bar", tabs: tabs()}
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
