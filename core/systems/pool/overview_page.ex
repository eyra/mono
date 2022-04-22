defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :studentpool
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias Systems.Pool.{StudentsView, CampaignsView, DashboardView}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent}

  data(tabs, :any)
  data(initial_tab, :any)

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    {
      :ok,
      socket
      |> assign_viewport()
      |> assign_breakpoint()
      |> assign(initial_tab: initial_tab)
      |> update_tabs()
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => nil}, session, socket)
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_tabs()
  end

  defp update_tabs(%{assigns: %{breakpoint: breakpoint, initial_tab: initial_tab}} = socket) do
    tabs = [
      %{
        id: :students,
        title: dgettext("link-studentpool", "tabbar.item.students"),
        component: StudentsView,
        props: %{},
        type: :fullpage,
        active: initial_tab === :students
      },
      %{
        id: :campaigns,
        title: dgettext("link-studentpool", "tabbar.item.campaigns"),
        component: CampaignsView,
        props: %{},
        type: :fullpage,
        active: initial_tab === :campaigns
      },
      %{
        id: :dashboard,
        title: dgettext("link-studentpool", "tabbar.item.dashboard"),
        component: DashboardView,
        props: %{breakpoint: breakpoint},
        type: :fullpage,
        active: initial_tab === :dashboard
      }
    ]

    socket |> assign(tabs: tabs)
  end

  def render(assigns) do
    ~F"""
      <Workspace
        title={dgettext("link-studentpool", "title")}
        menus={@menus}
      >
        <div id={:pool_overview} phx-hook="ViewportResize">
          <TabbarArea tabs={@tabs}>
            <ActionBar>
              <Tabbar vm={%{initial_tab: @initial_tab, size: :wide, type: :segmented}} />
            </ActionBar>
            <TabbarContent/>
          </TabbarArea>
        </div>
      </Workspace>
    """
  end
end
