defmodule Systems.Admin.ActionsView do
  use CoreWeb, :live_component
  use Core.FeatureFlags

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text

  alias Systems.Advert
  alias Systems.Assignment

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

    crash_button = %{
      action: %{
        type: :send,
        event: "crash"
      },
      face: %{
        type: :primary,
        bg_color: "bg-delete",
        label: "Raise a test exception"
      }
    }

    socket
    |> assign(
      rollback_expired_deposits_button: rollback_expired_deposits_button,
      expire_button: expire_button,
      expire_force_button: expire_force_button,
      crash_button: crash_button
    )
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
  def handle_event("expire_force", _, socket) do
    Advert.Public.mark_expired_debug(true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("expire", _, socket) do
    Advert.Public.mark_expired_debug()
    {:noreply, socket}
  end

  @impl true
  def handle_event("crash", _, socket) do
    raise "Test exception"
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-admin", "actions.title") %></Text.title2>

      <Text.title3 margin="">Book keeping & Finance</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@rollback_expired_deposits_button} />
        <.spacing value="S" />
      </.wrap>
      <.spacing value="XL" />
      <Text.title3 margin="">Assignments</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@expire_button} />
        <.spacing value="S" />
      </.wrap>
      <.spacing value="XL" />
      <Text.title3 margin="">Monitoring</Text.title3>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@crash_button} />
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
