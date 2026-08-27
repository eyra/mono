defmodule CoreWeb.Live.Feature.Actions do
  @moduledoc false
  def create_actions(%{assigns: %{vm: %{actions: actions}}}), do: Keyword.values(actions)
  def create_actions(_socket), do: []

  defmacro __using__(_opts \\ nil) do
    quote do
      import CoreWeb.Live.Feature.Actions

      # stubs, handled by Live Hooks
      def handle_event("action_click", _, socket), do: {:noreply, socket}
      def handle_info(:action_clicked, socket), do: {:noreply, socket}

      def update_actions(socket) do
        assign(socket, actions: create_actions(socket))
      end
    end
  end
end
