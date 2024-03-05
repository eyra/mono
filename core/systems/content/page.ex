defmodule Systems.Content.Page do
  use CoreWeb, :html

  import CoreWeb.Layouts.Workspace.Component
  import CoreWeb.UI.PlainDialog
  import CoreWeb.UI.Popup

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation
  alias CoreWeb.UI.Responsive.Breakpoint

  defp margin_x(:mobile), do: "mx-6"
  defp margin_x(_), do: "mx-10"

  attr(:title, :string, required: true)
  attr(:menus, :map, required: true)
  attr(:actions, :list, default: [])
  attr(:more_actions, :list, default: [])
  attr(:tabs, :list, default: [])
  attr(:tabbar_id, :atom, required: true)
  attr(:tabbar_size, :any, required: true)
  attr(:initial_tab, :atom, default: nil)
  attr(:show_errors, :boolean, default: false)
  attr(:popup, :map, default: nil)
  attr(:dialog, :map, default: nil)
  attr(:breakpoint, :atom, default: nil)

  def content_page(assigns) do
    ~H"""
    <.workspace title={@title} menus={@menus} >
      <:top_bar>
        <Navigation.action_bar right_bar_buttons={@actions} more_buttons={@more_actions}>
            <Tabbar.container id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} size={@tabbar_size} />
        </Navigation.action_bar>
      </:top_bar>

      <div>
        <div id={:content} phx-hook="ViewportResize">

          <%= if @popup do %>
            <.popup>
              <div class={"#{margin_x(@breakpoint)} w-full max-w-popup sm:max-w-popup-sm md:max-w-popup-md lg:max-w-popup-lg"}>
                <.live_component module={@popup.module} {@popup.props} />
              </div>
            </.popup>
          <% end %>

          <%= if @dialog do %>
            <.popup>
              <div class="flex-wrap">
                <.plain_dialog {@dialog} />
              </div>
            </.popup>
          <% end %>

          <div id="assignment" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbar.content tabs={@tabs} />
          </div>
          <Tabbar.footer tabs={@tabs} />
        </div>
      </div>
    </.workspace>
    """
  end

  def create_actions(%{assigns: %{breakpoint: {:unknown, _}}} = _socket), do: []

  def create_actions(%{assigns: %{vm: %{actions: actions}}} = socket) do
    actions
    |> Keyword.keys()
    |> Enum.map(&create_action(Keyword.get(actions, &1), socket))
    |> Enum.filter(&(not is_nil(&1)))
  end

  def create_action(action, %{assigns: %{breakpoint: breakpoint}}) do
    Breakpoint.value(breakpoint, nil,
      xs: %{0 => action.icon},
      md: %{40 => action.label, 100 => action.icon},
      lg: %{50 => action.label}
    )
  end

  def tabbar_size({:unknown, _}), do: :unknown
  def tabbar_size(bp), do: Breakpoint.value(bp, :narrow, sm: %{30 => :wide})

  defmacro __using__(_) do
    quote do
      use CoreWeb.Layouts.Workspace.Component, :projects
      use CoreWeb.UI.Responsive.Viewport
      use Systems.Observatory.Public

      alias CoreWeb.LiveLocale
      alias Frameworks.Pixel.Flash

      import CoreWeb.Gettext
      import Systems.Content.Page, except: [helpers: 0]

      defp initialize(socket, id, model, tabbar_id, initial_tab) do
        socket
        |> assign(
          id: id,
          model: model,
          tabbar_id: tabbar_id,
          initial_tab: initial_tab,
          locale: LiveLocale.get_locale(),
          changesets: %{},
          publish_clicked: false,
          dialog: nil,
          popup: nil,
          side_panel: nil,
          action_map: %{},
          more_actions: []
        )
        |> assign_viewport()
        |> assign_breakpoint()
        |> update_tabbar_size()
        |> update_menus()
      end

      defoverridable handle_uri: 1

      @impl true
      def handle_uri(socket) do
        socket =
          socket
          |> observe_view_model()
          |> update_actions()
          |> update_menus()

        super(socket)
      end

      def handle_view_model_updated(socket) do
        socket
        |> update_actions()
        |> update_menus()
      end

      @impl true
      def handle_resize(socket) do
        socket
        |> update_tabbar_size()
        |> update_actions()
        |> update_menus()
      end

      @impl true
      def handle_event(
            "action_click",
            %{"item" => action_id},
            %{assigns: %{vm: %{actions: actions}}} = socket
          ) do
        action_id = String.to_existing_atom(action_id)
        action = Keyword.get(actions, action_id)

        {
          :noreply,
          socket
          |> action.handle_click.()
          |> update_view_model()
          |> update_actions()
        }
      end

      @impl true
      def handle_event("inform_ok", _params, socket) do
        {:noreply, socket |> assign(dialog: nil)}
      end

      @impl true
      def handle_event("show_popup", %{ref: %{id: id, module: module}, params: params}, socket) do
        popup = %{module: module, props: Map.put(params, :id, id)}
        handle_event("show_popup", popup, socket)
      end

      @impl true
      def handle_event("show_popup", %{module: _, props: _} = popup, socket) do
        {:noreply, socket |> assign(popup: popup)}
      end

      @impl true
      def handle_event("hide_popup", _, socket) do
        {:noreply, socket |> assign(popup: nil)}
      end

      @impl true
      def handle_info({:handle_auto_save_done, _}, socket) do
        socket |> update_menus()
        {:noreply, socket}
      end

      @impl true
      def handle_info({:flash, type, message}, socket) do
        socket |> Flash.put(type, message, true)
        {:noreply, socket}
      end

      @impl true
      def handle_info({:show_popup, popup}, socket) do
        {:noreply, socket |> assign(popup: popup)}
      end

      @impl true
      def handle_info({:hide_popup}, socket) do
        {:noreply, socket |> assign(popup: nil)}
      end

      @impl true
      def handle_info(%{id: form_id, ready?: ready?}, socket) do
        ready_key = String.to_atom("#{form_id}_ready?")

        socket =
          if socket.assigns[ready_key] != ready? do
            socket
            |> assign(ready_key, ready?)
          else
            socket
          end

        {:noreply, socket}
      end

      @impl true
      def handle_info({:signal_test, _}, socket) do
        {:noreply, socket}
      end

      def update_actions(socket) do
        socket
        |> assign(actions: create_actions(socket))
      end

      def update_tabbar_size(%{assigns: %{breakpoint: breakpoint}} = socket) do
        tabbar_size = tabbar_size(breakpoint)
        socket |> assign(tabbar_size: tabbar_size)
      end
    end
  end
end
