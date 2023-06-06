defmodule Systems.Support.OverviewPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :support
  use CoreWeb.UI.Responsive.Viewport

  require Systems.Support.TicketStatus

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  alias Systems.{
    Support
  }

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(tabbar_id: "support_overview")
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

  defp create_tabs(socket) do
    tabs =
      Support.TicketStatus.values()
      |> Enum.map(&{&1, Support.Public.list_tickets(&1)})
      |> Enum.map(fn {status, tickets} ->
        %{
          id: status,
          ready: true,
          title: Support.TicketStatus.translate(status),
          count: Enum.count(tickets),
          type: :fullpage,
          live_component: Systems.Support.OverviewTab,
          props: %{
            tickets: tickets
          }
        }
      end)

    socket
    |> assign(tabs: tabs)
  end

  defp tabbar_size({:unknown, _}), do: :unknown
  defp tabbar_size(bp), do: value(bp, :narrow, sm: %{30 => :wide})

  # data(tabbar_id, :string)
  # data(tabs, :list)
  # data(tabbar_size, :number)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-admin", "support.title")} menus={@menus}>
      <div id={:support} phx-hook="ViewportResize">
        <Navigation.action_bar>
          <Tabbar.container id={@tabbar_id} tabs={@tabs} size={@tabbar_size} />
        </Navigation.action_bar>
        <Tabbar.content tabs={@tabs} />
      </div>
    </.workspace>
    """
  end
end
