defmodule Link.Onboarding do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped
  alias CoreWeb.User.Forms.Profile, as: ProfileForm
  alias CoreWeb.User.Forms.Study, as: StudyForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  alias EyraUI.Button.Action.Redirect
  alias EyraUI.Button.Face.Primary
  alias EyraUI.Navigation.{Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  data(user_agent, :string, default: "")
  data(current_user, :any)
  data(tabs, :any)

  def mount(_params, _session, socket) do
    tabs = create_tabs(socket)

    {
      :ok,
      socket
      |> assign(
        tabs: tabs,
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
    }
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

  defp create_tabs(%{assigns: %{current_user: current_user}}) do
    []
    |> append(%{
      id: :profile,
      title: dgettext("eyra-ui", "tabbar.item.profile"),
      forward_title: dgettext("eyra-ui", "tabbar.item.profile.forward"),
      component: ProfileForm
    })
    |> append(
      %{
        id: :study,
        title: dgettext("eyra-ui", "tabbar.item.study"),
        forward_title: dgettext("eyra-ui", "tabbar.item.study.forward"),
        component: StudyForm
      },
      current_user.student
    )
    |> append(%{
      id: :features,
      action: nil,
      title: dgettext("eyra-ui", "tabbar.item.features"),
      forward_title: dgettext("eyra-ui", "tabbar.item.features.forward"),
      component: FeaturesForm
    })
  end

  defp forward_path(socket) do
    page = forward_page(socket)
    Routes.live_path(socket, page)
  end

  defp forward_page(%{assigns: %{current_user: %{researcher: true}}}), do: Link.Dashboard
  defp forward_page(_), do: Link.Marketplace

  @impl true
  def render(assigns) do
    ~H"""
      <Stripped
        user={{@current_user}}
        active_item={{ :dashboard }}
      >
        <TabbarArea tabs={{@tabs}}>
          <Tabbar id={{ :tabbar }}/>
          <TabbarContent user={{@current_user}} />
          <TabbarFooter>
              <Redirect to={{ forward_path(@socket) }}>
                <Primary label={{ dgettext("eyra-ui", "onboarding.forward") }}/>
              </Redirect>
          </TabbarFooter>
        </TabbarArea>
      </Stripped>
    """
  end
end
