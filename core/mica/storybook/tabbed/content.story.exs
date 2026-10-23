defmodule Storybook.Frameworks.Pixel.Tabbed.Content do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Tabbed.content/1

  import Phoenix.Component, only: [sigil_H: 2]

  # Panels and footer items stay hidden until the TabBar hook activates a tab, so a real bar is rendered above.
  def template do
    """
    <div class="flex flex-col gap-6" psb-code-hidden>
      <Frameworks.Pixel.Tabbed.bar id="content_bar" initial_tab="workflow" tabs={Storybook.Frameworks.Pixel.Tabbed.Content.tabs()} />
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :function_components,
        description: "One panel per tab; click a tab above to switch panels",
        attributes: %{
          socket: nil,
          bar_id: "content_bar",
          tabs: [
            panel_tab(
              "settings",
              "Settings",
              "Name the assignment and choose the language participants see."
            ),
            panel_tab(
              "workflow",
              "Workflow",
              "Add the tasks participants complete, in order: consent, questionnaire, data donation."
            ),
            panel_tab(
              "monitor",
              "Monitor",
              "12 participants started, 9 finished, 1 donation awaits review."
            )
          ]
        }
      }
    ]
  end

  def panel_body(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <Frameworks.Pixel.Text.title3>{@title}</Frameworks.Pixel.Text.title3>
      <Frameworks.Pixel.Text.body_large>{@text}</Frameworks.Pixel.Text.body_large>
    </div>
    """
  end

  defp panel_tab(id, title, text) do
    %{id: id, function_component: &__MODULE__.panel_body/1, props: %{title: title, text: text}}
  end

  def tabs do
    [
      %{id: "settings", title: "Settings", forward_title: "Go to Settings", type: :fullpage},
      %{id: "workflow", title: "Workflow", forward_title: "Go to Workflow", type: :fullpage},
      %{id: "monitor", title: "Monitor", forward_title: "Go to Monitor", type: :fullpage}
    ]
  end
end
