defmodule Systems.Admin.ConfigPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :admin
  use CoreWeb.UI.Responsive.Viewport

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        locale: LiveLocale.get_locale(),
        tabbar_id: "admin",
        popup: nil
      )
      |> assign_breakpoint()
      |> create_tabs()
      |> update_tabbar()
      |> update_menus()
    }
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_tabbar()
    |> update_menus()
  end

  defp update_tabbar(%{assigns: %{breakpoint: breakpoint}} = socket) do
    tabbar_size = tabbar_size(breakpoint)

    socket
    |> assign(tabbar_size: tabbar_size)
  end

  defp create_tabs(%{assigns: %{locale: locale, current_user: user}} = socket) do
    tabs = [
      %{
        id: :system,
        ready: true,
        title: dgettext("eyra-admin", "system.title"),
        type: :fullpage,
        live_component: Systems.Admin.SystemView,
        props: %{
          locale: locale,
          user: user
        }
      },
      %{
        id: :org,
        ready: true,
        title: dgettext("eyra-admin", "org.content.title"),
        type: :fullpage,
        live_component: Systems.Admin.OrgView,
        props: %{
          locale: locale
        }
      },
      %{
        id: :actions,
        ready: true,
        title: dgettext("eyra-admin", "actions.title"),
        type: :fullpage,
        live_component: Systems.Admin.ActionsView,
        props: %{
          tickets: []
        }
      }
    ]

    socket
    |> assign(tabs: tabs)
  end

  defp tabbar_size({:unknown, _}), do: :unknown
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{30 => :wide})

  @impl true
  def handle_info({:show_popup, popup}, socket) do
    {:noreply, socket |> assign(popup: popup)}
  end

  @impl true
  def handle_info({:hide_popup}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  # data(tabbar_id, :string)
  # data(tabs, :list)
  # data(bar_size, :number)
  # data(popup, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-admin", "config.title")} menus={@menus}>
      <%= if @popup do %>
        <.popup>
          <div class="p-8 w-popup-md bg-white shadow-floating rounded">
            <.live_component id={:config_page_popup} module={@popup.module} {@popup} />
          </div>
        </.popup>
      <% end %>

      <Navigation.action_bar>
        <Tabbar.container id={@tabbar_id} tabs={@tabs} size={@tabbar_size} type={:segmented} />
      </Navigation.action_bar>
      <Tabbar.content tabs={@tabs} />
    </.workspace>
    """
  end
end
