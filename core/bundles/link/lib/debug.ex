defmodule Link.Debug do
  @moduledoc """
  The debug screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :debug
  alias CoreWeb.Router.Helpers, as: Routes

  alias CoreWeb.User.Forms.Debug, as: UserDebugForm
  alias Systems.Email.DebugForm, as: EmailDebugForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Button.DynamicButton

  alias Frameworks.Pixel.Container.{Wrap}
  alias Frameworks.Pixel.Text.Title2

  alias Systems.{
    Campaign,
    Budget,
    Scholar
  }

  data(multiply_rewards_button, :map)
  data(generate_vu_2022_button, :map)
  data(import_rewards_button, :map)
  data(sync_rewards_button, :map)
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

    multiply_rewards_button = %{
      action: %{
        type: :send,
        event: "multiply_rewards_year2_2021"
      },
      face: %{
        type: :primary,
        label: "Multiply rewards year2 2021 x 10"
      }
    }

    generate_vu_2022_button = %{
      action: %{
        type: :send,
        event: "generate_vu_2022"
      },
      face: %{
        type: :primary,
        label: "Generate VU Academic Year 2022"
      }
    }

    import_rewards_button = %{
      action: %{
        type: :send,
        event: "import_rewards"
      },
      face: %{
        type: :primary,
        label: "Import student rewards"
      }
    }

    sync_rewards_button = %{
      action: %{
        type: :send,
        event: "sync_rewards"
      },
      face: %{
        type: :primary,
        label: "Sync student credits"
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
        multiply_rewards_button: multiply_rewards_button,
        generate_vu_2022_button: generate_vu_2022_button,
        import_rewards_button: import_rewards_button,
        sync_rewards_button: sync_rewards_button,
        start_button: start_button,
        expire_button: expire_button,
        expire_force_button: expire_force_button,
        changesets: %{}
      )
      |> update_menus()
    }
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
  def handle_event("generate_vu_2022", _, socket) do
    Scholar.Context.generate_vu(2022, 1, "1st", "1e", 60)
    Scholar.Context.generate_vu(2022, 2, "2nd", "2e", 30)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("multiply_rewards_year2_2021", _, socket) do
    Budget.Context.multiply_rewards("vu_sbe_rpr_year2_2021", 10)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("import_rewards", _, %{assigns: %{uri_path: uri_path}} = socket) do
    {:noreply,
     push_redirect(socket,
       to: Routes.live_path(socket, Systems.Admin.ImportRewardsPage, back: uri_path)
     )}
  end

  @impl true
  def handle_event("sync_rewards", _, socket) do
    Campaign.Context.sync_student_credits()
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

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
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
    ~F"""
    <Workspace title={dgettext("link-ui", "debug.title")} menus={@menus}>
      <MarginY id={:page_top} />
      <ContentArea>
        <MarginY id={:page_top} />
        <Title2 margin="">VU</Title2>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={@multiply_rewards_button} />
          <Spacing value="S" />
        </Wrap>
        <Wrap>
          <DynamicButton vm={@generate_vu_2022_button} />
          <Spacing value="S" />
        </Wrap>
        <Spacing value="XL" />

        <Title2 margin="">Book keeping</Title2>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={@import_rewards_button} />
          <Spacing value="S" />
        </Wrap>
        <Wrap>
          <DynamicButton vm={@sync_rewards_button} />
        </Wrap>
        <Spacing value="XL" />
        <Title2 margin="">Campaigns</Title2>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={@expire_button} />
          <Spacing value="S" />
        </Wrap>
        <div :if={feature_enabled?(:debug_expire_force)}>
          <Wrap>
            <DynamicButton vm={@expire_force_button} />
          </Wrap>
        </div>
        <Spacing value="XL" />

        <Title2 margin="">Onboarding</Title2>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={@start_button} />
        </Wrap>
      </ContentArea>

      <Spacing value="XL" />
      <UserDebugForm id={:user_debug} user={@current_user} />
      <Spacing value="XL" />
      <EmailDebugForm id={:mail_debug} user={@current_user} />
    </Workspace>
    """
  end
end
