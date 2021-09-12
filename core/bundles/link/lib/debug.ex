defmodule Link.Debug do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.MultiFormAutoSave
  use CoreWeb.Layouts.Workspace.Component, :debug

  alias CoreWeb.User.Forms.Debug, as: UserDebugForm
  alias CoreWeb.Mail.Forms.Debug, as: MailDebugForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Spacing
  alias EyraUI.Button.DynamicButton

  alias EyraUI.Container.{Wrap}
  alias EyraUI.Text.Title2

  def mount(_params, _session, socket) do
    require_feature(:debug)

    start_button = %{
      action: %{
        type: :redirect,
        to: Routes.live_path(socket, Link.Onboarding.Wizard)
      },
      face: %{
        type: :primary,
        label: "Start onboarding flow"
      }
    }

    {
      :ok,
      socket
      |> assign(
        start_button: start_button,
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

  def handle_info({:claim_focus, :mail_debug}, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-ui", "debug.title") }}
        menus={{ @menus }}
      >
        <MarginY id={{:page_top}} />
        <ContentArea>
          <MarginY id={{:page_top}} />
            <Title2 margin="">Onboarding</Title2>
            <Spacing value="S" />
            <Wrap>
              <DynamicButton vm={{ @start_button }} />
            </Wrap>
        </ContentArea>

        <Spacing value="XL" />
        <UserDebugForm id={{:user_debug}} user={{@current_user }}/>
        <Spacing value="XL" />
        <MailDebugForm id={{:mail_debug}} />

        <MarginY id={{:page_footer_top}} />
      </Workspace>
    """
  end
end
