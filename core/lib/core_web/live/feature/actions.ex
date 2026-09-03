defmodule CoreWeb.Live.Feature.Actions do
  def create_actions(%{assigns: %{vm: %{actions: actions}}}), do: Keyword.values(actions)
  def create_actions(_socket), do: []

  def create_more_actions(%{assigns: %{vm: %{more_actions: more_actions}}}),
    do: Keyword.values(more_actions)

  def create_more_actions(_socket), do: []

  defmacro __using__(_opts \\ nil) do
    quote do
      import CoreWeb.Live.Feature.Actions

      # stubs, handled by Live Hooks
      def handle_event("action_click", _, socket), do: {:noreply, socket}
      def handle_info(:action_clicked, socket), do: {:noreply, socket}

      def update_actions(socket) do
        assign(socket,
          actions: create_actions(socket),
          more_actions: create_more_actions(socket)
        )
      end
    end
  end
end
