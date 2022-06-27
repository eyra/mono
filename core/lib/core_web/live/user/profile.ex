defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :profile
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias Core
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.User.Forms.Profile, as: ProfileForm
  alias CoreWeb.User.Forms.Study, as: StudyForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  alias CoreWeb.UI.Navigation.{ActionBar, Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  data(user_agent, :string, default: "")
  data(current_user, :any)
  data(tabs, :any)
  data(initial_tab, :any)
  data(bar_size, :any)

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    tabs = create_tabs(socket)

    {
      :ok,
      socket
      |> assign(
        tabs: tabs,
        initial_tab: initial_tab,
        changesets: %{}
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> update_tabbar()
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => nil}, session, socket)
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(ProfileForm, id: :profile, focus: "")
    {:noreply, socket}
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_tabbar()
  end

  defp update_tabbar(%{assigns: %{breakpoint: breakpoint}} = socket) do
    bar_size = bar_size(breakpoint)

    socket
    |> assign(bar_size: bar_size)
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :profile}, socket) do
    # Profile is currently only form that can claim focus
    {:noreply, socket}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  defp append(list, extra, cond \\ true) do
    if cond, do: list ++ [extra], else: list
  end

  defp create_tabs(%{assigns: %{current_user: current_user}}) do
    []
    |> append(%{
      id: :profile,
      title: dgettext("eyra-ui", "tabbar.item.profile"),
      forward_title: dgettext("eyra-ui", "tabbar.item.profile.forward"),
      type: :form,
      component: ProfileForm,
      props: %{user: current_user}
    })
    |> append(
      %{
        id: :study,
        title: dgettext("eyra-ui", "tabbar.item.study"),
        forward_title: dgettext("eyra-ui", "tabbar.item.study.forward"),
        type: :form,
        component: StudyForm,
        props: %{user: current_user}
      },
      current_user.student
    )
    |> append(%{
      id: :features,
      action: nil,
      title: dgettext("eyra-ui", "tabbar.item.features"),
      forward_title: dgettext("eyra-ui", "tabbar.item.features.forward"),
      type: :form,
      component: FeaturesForm,
      props: %{user: current_user}
    })
  end

  defp bar_size({:unknown, _}), do: :unknown
  defp bar_size(bp), do: value(bp, :narrow, xs: %{45 => :wide})

  @impl true
  def render(assigns) do
    ~F"""
    <Workspace menus={@menus}>
      <div id={:profile} phx-hook="ViewportResize">
        <TabbarArea tabs={@tabs}>
          <ActionBar size={@bar_size}>
            <Tabbar vm={%{initial_tab: @initial_tab, size: @bar_size, type: :segmented}} />
          </ActionBar>
          <TabbarContent />
          <TabbarFooter />
        </TabbarArea>
      </div>
    </Workspace>
    """
  end
end
