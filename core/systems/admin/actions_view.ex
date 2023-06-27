defmodule Systems.Admin.ActionsView do
  use CoreWeb, :live_component
  use Core.FeatureFlags

  alias CoreWeb.Router.Helpers, as: Routes
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text

  alias Systems.{
    Campaign,
    Budget,
    Student,
    Assignment
  }

  @impl true
  def update(%{id: id}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> create_buttons()
    }
  end

  def create_buttons(socket) do
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

    rollback_expired_deposits_button = %{
      action: %{
        type: :send,
        event: "rollback_expired_deposits"
      },
      face: %{
        type: :primary,
        label: "Rollback expired deposits"
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

    socket
    |> assign(
      rollback_expired_deposits_button: rollback_expired_deposits_button,
      multiply_rewards_button: multiply_rewards_button,
      generate_vu_2022_button: generate_vu_2022_button,
      import_rewards_button: import_rewards_button,
      sync_rewards_button: sync_rewards_button,
      expire_button: expire_button,
      expire_force_button: expire_force_button
    )
  end

  @impl true
  def handle_event("generate_vu_2022", _, socket) do
    Student.Public.generate_vu(2022, 1, "1st", "1e", 60)
    Student.Public.generate_vu(2022, 2, "2nd", "2e", 30)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("rollback_expired_deposits", _, socket) do
    sixty_days = 60 * 24 * 60
    from_sixty_days_ago = Timestamp.naive_from_now(-sixty_days)
    Assignment.Public.rollback_expired_deposits(from_sixty_days_ago)

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("multiply_rewards_year2_2021", _, socket) do
    Budget.Public.multiply_rewards("vu_sbe_rpr_year2_2021", 10)

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
    Campaign.Public.sync_student_credits()
    {:noreply, socket}
  end

  @impl true
  def handle_event("expire_force", _, socket) do
    Campaign.Public.mark_expired_debug(true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("expire", _, socket) do
    Campaign.Public.mark_expired_debug()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-admin", "actions.title") %></Text.title2>

      <Text.title3 margin="">VU</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@multiply_rewards_button} />
        <.spacing value="S" />
      </.wrap>
      <.wrap>
        <Button.dynamic {@generate_vu_2022_button} />
        <.spacing value="S" />
      </.wrap>
      <.spacing value="XL" />

      <Text.title3 margin="">Book keeping</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@rollback_expired_deposits_button} />
        <.spacing value="S" />
      </.wrap>
      <.wrap>
        <Button.dynamic {@import_rewards_button} />
        <.spacing value="S" />
      </.wrap>
      <.wrap>
        <Button.dynamic {@sync_rewards_button} />
      </.wrap>
      <.spacing value="XL" />
      <Text.title3 margin="">Campaigns</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@expire_button} />
        <.spacing value="S" />
      </.wrap>
      <%= if feature_enabled?(:debug_expire_force) do %>
        <.wrap>
          <Button.dynamic {@expire_force_button} />
        </.wrap>
      <% end %>
      </Area.content>
    </div>
    """
  end
end
