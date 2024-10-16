defmodule CoreWeb.Live.Feature.Actions do
  alias CoreWeb.UI.Responsive.Breakpoint

  def create_actions(%{assigns: %{breakpoint: {:unknown, _}}} = _socket), do: []

  def create_actions(%{assigns: %{vm: %{actions: actions}}} = socket) do
    actions
    |> Keyword.keys()
    |> Enum.map(&create_action(Keyword.get(actions, &1), socket))
    |> Enum.filter(&(not is_nil(&1)))
  end

  def create_actions(_socket), do: []

  def create_action(action, %{assigns: %{breakpoint: breakpoint}}) do
    Breakpoint.value(breakpoint, nil,
      xs: %{0 => action.icon},
      md: %{40 => action.label, 100 => action.icon},
      lg: %{50 => action.label}
    )
  end

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
