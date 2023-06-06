defmodule Systems.Survey.ExperimentTaskView do
  use CoreWeb, :live_component

  alias Frameworks.Utility.LiveCommand
  import CoreWeb.UI.Navigation, only: [button_bar: 1]

  @impl true
  def handle_event(event, _params, socket) do
    {:noreply, LiveCommand.execute(event, socket)}
  end

  defp action_buttons(%{actions: actions, myself: target}) do
    LiveCommand.action_buttons(actions, target)
  end

  attr(:actions, :list, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Margin.y id={:button_bar_top} />
      <.button_bar buttons={action_buttons(assigns)} />
      <.spacing value="XL" />
    </div>
    """
  end
end
