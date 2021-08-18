defmodule Link.Debug do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :debug

  alias CoreWeb.User.Forms.Debug, as: UserDebugForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Spacing
  alias EyraUI.Button.Action.Redirect
  alias EyraUI.Button.Face.Primary

  alias EyraUI.Container.{ContentArea, Wrap}
  alias EyraUI.Text.Title2


  def mount(_params, _session, socket) do
    require_feature(:debug)

    {
      :ok,
      socket
      |> assign(
        changesets: %{},
        save_timer: nil,
        hide_flash_timer: nil
      )
      |> update_menus()
    }
  end

  @impl true
  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    send_update(UserDebugForm, id: :user_debug, focus: "")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :user_debug}, socket) do
    # UserDebugForm is currently only form that can claim focus
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-ui", "debug.title") }}
        menus={{ @menus }}
      >
        <UserDebugForm id={{:user_debug}} user={{@current_user }}/>
        <Spacing value="M" />
        <ContentArea>
          <Wrap>
            <Title2>Onboarding</Title2>
            <Redirect to={{ Routes.live_path(@socket, Link.Onboarding.Wizard) }}>
              <Primary label="Start onboarding flow" />
            </Redirect>
          </Wrap>
        </ContentArea>
      </Workspace>
    """
  end
end
