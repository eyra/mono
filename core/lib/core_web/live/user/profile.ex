defmodule CoreWeb.User.Profile do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :profile

  import CoreWeb.Gettext

  alias Core
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.User.Forms.Profile, as: ProfileForm
  alias CoreWeb.User.Forms.Study, as: StudyForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  alias EyraUI.Navigation.{Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  data(user_agent, :string, default: "")
  data(current_user, :any)
  data(tabs, :any)

  @impl true
  def mount(%{"tab" => active_tab}, _session, socket) do
    tabs = create_tabs(socket, String.to_atom(active_tab))

    {
      :ok,
      socket
      |> assign(
        tabs: tabs,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => "profile"}, session, socket)
  end

  @impl true
  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(ProfileForm, id: :profile, focus: "")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :profile}, socket) do
    # Profile is currently only form that can claim focus
    {:noreply, socket}
  end

  defp append(list, extra, cond \\ true) do
    if cond, do: list ++ [extra], else: list
  end

  defp create_tabs(%{assigns: %{current_user: current_user}}, active_tab) do
    []
    |> append(%{
      id: :profile,
      title: dgettext("eyra-ui", "tabbar.item.profile"),
      forward_title: dgettext("eyra-ui", "tabbar.item.profile.forward"),
      component: ProfileForm,
      active: active_tab === :profile
    })
    |> append(
      %{
        id: :study,
        title: dgettext("eyra-ui", "tabbar.item.study"),
        forward_title: dgettext("eyra-ui", "tabbar.item.study.forward"),
        component: StudyForm,
        active: active_tab === :study
      },
      current_user.student
    )
    |> append(%{
      id: :features,
      action: nil,
      title: dgettext("eyra-ui", "tabbar.item.features"),
      forward_title: dgettext("eyra-ui", "tabbar.item.features.forward"),
      component: FeaturesForm,
      active: active_tab === :features
    })
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Workspace menus={{ @menus }}>
      <TabbarArea tabs={{@tabs}}>
        <Tabbar id={{ :tabbar }}/>
        <TabbarContent user={{@current_user}} />
        <TabbarFooter/>
      </TabbarArea>
    </Workspace>
    """
  end
end
