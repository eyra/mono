defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :studentpool
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent}

  data(tabs, :any)
  data(initial_tab, :any)

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    model = %{id: :sbe_2021, director: :pool}

    {
      :ok,
      socket
      |> assign(
        model: model,
        initial_tab: initial_tab
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> observe_view_model()
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => nil}, session, socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_view_model()
  end

  def render(assigns) do
    ~F"""
      <Workspace
        title={dgettext("link-studentpool", "title")}
        menus={@menus}
      >
        <div id={:pool_overview} phx-hook="ViewportResize">
          <TabbarArea tabs={@vm.tabs}>
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
