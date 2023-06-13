defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :profile
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias Core
  import CoreWeb.Layouts.Workspace.Component
  alias CoreWeb.User.Forms.Profile, as: ProfileForm
  alias CoreWeb.User.Forms.Student, as: StudentForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  alias CoreWeb.UI.Tabbar
  alias CoreWeb.UI.Navigation

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    tabs = create_tabs(socket)
    tabbar_id = "user_profile"

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
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
      live_component: ProfileForm,
      props: %{user: current_user}
    })
    |> append(
      %{
        id: :student,
        title: dgettext("eyra-ui", "tabbar.item.student"),
        forward_title: dgettext("eyra-ui", "tabbar.item.student.forward"),
        type: :form,
        live_component: StudentForm,
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
      live_component: FeaturesForm,
      props: %{user: current_user}
    })
  end

  defp bar_size({:unknown, _}), do: :unknown
  defp bar_size(bp), do: value(bp, :narrow, xs: %{45 => :wide})

  # data(user_agent, :string, default: "")
  # data(current_user, :any)
  # data(tabs, :any)
  # data(initial_tab, :any)
  # data(bar_size, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace menus={@menus}>
      <div id={:profile} phx-hook="ViewportResize">
        <Navigation.action_bar size={@bar_size}>
          <Tabbar.container id={@tabbar_id} tabs={@tabs} initial_tab={@initial_tab} size={@bar_size} type={:segmented} />
        </Navigation.action_bar>
        <Tabbar.content tabs={@tabs} />
      </div>
    </.workspace>
    """
  end
end
