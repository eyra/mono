defmodule Systems.Support.OverviewPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :support
  use CoreWeb.UI.Responsive.Viewport

  require Systems.Support.TicketStatus

  alias CoreWeb.UI.Navigation.{
    ActionBar,
    TabbarArea,
    Tabbar,
    TabbarContent
  }

  alias Systems.{
    Support
  }

  data tabs, :list
  data bar_size, :number

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
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
      |> Enum.map(&({&1, Support.Context.list_tickets(&1)}))
      |> Enum.map(fn {status, tickets} ->
        %{
          id: status,
          ready?: true,
          title: Support.TicketStatus.translate(status),
          count: Enum.count(tickets),
          type: :fullpage,
          component: Systems.Support.OverviewTab,
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

  def render(assigns) do
    ~F"""
    <Workspace
      title={dgettext("eyra-admin", "support.title")}
      menus={@menus}
    >
      <div id={:support} phx-hook="ViewportResize">
        <TabbarArea tabs={@tabs}>
          <ActionBar>
            <Tabbar vm={%{size: @tabbar_size}} />
          </ActionBar>
          <TabbarContent/>
        </TabbarArea>
      </div>
    </Workspace>
    """
  end
end
