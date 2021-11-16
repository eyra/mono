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

  alias Systems.{
    Campaign
  }

  data(expire_button, :map)
  data(expire_force_button, :map)
  data(start_button, :map)

  def mount(_params, _session, socket) do
    expire_force_button = %{
      action: %{
        type: :send,
        event: "expire_force"
      },
      face: %{
        type: :primary,
        bg_color: "bg-delete",
        label: "Mark all pending tasks expired"
      }
    }

    expire_button = %{
      action: %{
        type: :send,
        event: "expire"
      },
      face: %{
        type: :primary,
        label: "Mark expired tasks"
      }
    }

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
        expire_button: expire_button,
        expire_force_button: expire_force_button,
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

  @impl true
  def handle_event("expire", _, socket) do
    Campaign.Context.mark_expired_debug()
    {:noreply, socket}
  end

  @impl true
  def handle_event("expire_force", _, socket) do
    Campaign.Context.mark_expired_debug(true)
    {:noreply, socket}
  end

  def handle_event("save", _, socket) do
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
            <Title2 margin="">Campaigns</Title2>
            <Spacing value="S" />
            <Wrap>
              <DynamicButton vm={{ @expire_button }} />
            <Spacing value="S" />
            </Wrap>
            <div :if={{ feature_enabled?(:debug_expire_force) }}>
              <Spacing value="S" />
              <Wrap>
                <DynamicButton vm={{ @expire_force_button }} />
              </Wrap>
            </div>
            <Spacing value="XL" />

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

      </Workspace>
    """
  end
end
