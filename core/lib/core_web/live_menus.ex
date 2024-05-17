defmodule CoreWeb.LiveMenus do
  defmacro __using__({menu_builder, menus}) do
    quote do
      @before_compile CoreWeb.LiveMenus
      import Phoenix.Component

      def builder, do: Application.fetch_env!(:core, unquote(menu_builder))

      def build_menu(%{active_menu_item: active_menu_item} = assigns, type) do
        builder().build_menu(assigns, type, active_menu_item)
      end

      def build_menu(%{vm: %{active_menu_item: active_menu_item}} = assigns, type) do
        builder().build_menu(assigns, type, active_menu_item)
      end

      def build_menus(%{assigns: assigns} = socket) do
        menus = build_menus(assigns)
        socket |> assign(menus: menus)
      end

      def build_menus(%{authorization_failed: true}), do: nil

      def build_menus(assigns) do
        Enum.reduce(unquote(menus), %{}, fn menu_id, acc ->
          Map.put(acc, menu_id, build_menu(assigns, menu_id))
        end)
      end

      def update_menus(socket) do
        socket
        |> build_menus()
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, socket) do
        {:ok, socket} = super(params, session, socket)
        {:ok, socket |> update_menus()}
      end

      defoverridable handle_uri: 1

      def handle_uri(socket) do
        super(socket)
        |> update_menus()
      end

      defoverridable handle_view_model_updated: 1

      @impl true
      def handle_view_model_updated(socket) do
        super(socket)
        |> update_menus()
      end
    end
  end
end
