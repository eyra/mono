defmodule Systems.Survey.ExperimentTaskView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Utility.LiveCommand
  alias CoreWeb.UI.Navigation.ButtonBar

  prop(actions, :list, required: true)

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, LiveCommand.execute(event, socket)}
  end

  defp action_buttons(%{actions: actions, myself: target}) do
    LiveCommand.action_buttons(actions, target)
  end

  def render(assigns) do
    ~F"""
    <div>
      <MarginY id={:button_bar_top} />
      <ButtonBar buttons={action_buttons(assigns)} />
      <Spacing value="XL" />
    </div>
    """
  end
end
