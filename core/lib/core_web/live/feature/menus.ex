defmodule CoreWeb.Live.Feature.Menus do
  @type menu_builder :: atom()
  @type menus :: list(atom())
  @type active_menu_item :: atom()

  @callback get_menus_config() ::
              {menu_builder(), menus()} | {menu_builder(), menus(), active_menu_item()} | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour CoreWeb.Live.Feature.Menus
      import Phoenix.Component, only: [assign: 2]

      @impl true
      def get_menus_config(), do: nil

      defoverridable get_menus_config: 0

      import Phoenix.Component

      def update_menus(%{assigns: %{authorization_failed: true}} = socket), do: socket

      def update_menus(%{assigns: %{menus_config: nil}} = socket),
        do: socket |> assign(menus: nil)

      def update_menus(
            %{assigns: %{menus_config: {menu_builder, menus}, active_menu_item: active_menu_item}} =
              socket
          ) do
        update_menus(socket, menu_builder, menus, active_menu_item)
      end

      def update_menus(socket, menu_builder, menus, active_menu_item) do
        user = Map.get(socket.assigns, :current_user)
        uri = Map.get(socket.assigns, :uri)

        menus = CoreWeb.Menus.build_menus(menu_builder, menus, active_menu_item, user, uri)
        socket |> assign(menus: menus)
      end
    end
  end
end
