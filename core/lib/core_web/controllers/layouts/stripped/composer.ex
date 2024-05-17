defmodule CoreWeb.Layouts.Stripped.Composer do
  import Phoenix.Component

  @menus [
    :mobile_navbar,
    :desktop_navbar
  ]

  def builder, do: Application.fetch_env!(:core, :stripped_menu_builder)

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

  def build_menus(assigns) do
    Enum.reduce(@menus, %{}, fn menu_id, acc ->
      Map.put(acc, menu_id, build_menu(assigns, menu_id))
    end)
  end

  def update_menus(socket) do
    socket
    |> build_menus()
  end

  defmacro __using__(_) do
    quote do
      @before_compile CoreWeb.Layouts.Stripped.Composer
      use CoreWeb.LiveUri
      use Systems.Observatory.Public
      use CoreWeb.UI.PlainDialog

      import CoreWeb.Layouts.Stripped.Composer
      import CoreWeb.Layouts.Stripped.Html
      import Systems.Content.Html, only: [live_stripped: 1]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @impl true
      def mount(params, session, %{assigns: %{authorization_failed: true}} = socket) do
        {:ok, socket}
      end

      @impl true
      def mount(params, session, socket) do
        {:ok, socket} = super(params, session, socket)

        {
          :ok,
          socket
          |> assign(active_menu_item: nil)
          |> update_menus()
        }
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
