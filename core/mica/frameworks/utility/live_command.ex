defmodule Frameworks.Utility.LiveCommand do
  defstruct [:function, :args]

  require Logger

  def live_command(function, args) do
    %Frameworks.Utility.LiveCommand{function: function, args: args}
  end

  def execute(event, socket) when is_binary(event) do
    socket
    |> get_action(event)
    |> execute(socket)
  end

  def execute(%{live_command: live_command}, socket), do: execute(live_command, socket)

  def execute(%{function: function, args: args}, socket) when is_function(function, 2) do
    function.(args, socket)
  end

  def execute(_, socket) do
    Logger.warning("Can not execute live command. No live command found in argument.")
    socket
  end

  defp get_action(%{assigns: %{actions: actions}}, event) do
    actions
    |> Enum.reduce(
      nil,
      &if action?(event, &1) do
        &1
      else
        &2
      end
    )
  end

  defp action?(event1, %{button: %{action: %{event: event2}}} = _action) do
    event1 == event2
  end

  defp action?(_event, _action) do
    false
  end

  def action_buttons(actions, target) do
    actions
    |> Enum.filter(&Map.has_key?(&1, :button))
    |> Enum.map(& &1.button)
    |> Enum.map(&Kernel.put_in(&1, [:action, :target], target))
  end
end
