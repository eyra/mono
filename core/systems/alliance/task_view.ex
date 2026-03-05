defmodule Systems.Alliance.TaskView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Navigation, only: [button_bar: 1]

  alias Frameworks.Utility.LiveCommand

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
