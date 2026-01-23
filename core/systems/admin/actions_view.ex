defmodule Systems.Admin.ActionsView do
  use CoreWeb, :live_component
  use Core.FeatureFlags

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text

  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Feldspar

  @impl true
  def update(%{id: id}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
      |> create_buttons()
      |> update_data_donation_stats()
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

    data_donation_cleanup_button = %{
      action: %{
        type: :send,
        event: "data_donation_cleanup"
      },
      face: %{
        type: :primary,
        label: "Run data donation cleanup"
      }
    }

    socket
    |> assign(
      rollback_expired_deposits_button: rollback_expired_deposits_button,
      expire_button: expire_button,
      expire_force_button: expire_force_button,
      crash_button: crash_button,
      data_donation_cleanup_button: data_donation_cleanup_button
    )
  end

  defp update_data_donation_stats(socket) do
    stats = Feldspar.DataDonationFolder.stats()
    retention_hours = Application.get_env(:core, :feldspar_data_donation)[:retention_hours] || 336

    assign(socket,
      data_donation_file_count: stats.file_count,
      data_donation_total_size: format_bytes(stats.total_size),
      data_donation_retention_hours: retention_hours
    )
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"

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
  def handle_event("data_donation_cleanup", _, socket) do
    %{}
    |> Feldspar.DataDonationCleanupWorker.new()
    |> Oban.insert()

    {
      :noreply,
      socket
      |> update_data_donation_stats()
    }
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
      <.spacing value="XL" />
      <Text.title3 margin="">Data Donations</Text.title3>
      <.spacing value="S" />
      <Text.body>
        Files: <%= @data_donation_file_count %> (<%= @data_donation_total_size %>)<br/>
        Retention: <%= @data_donation_retention_hours %> hours
      </Text.body>
      <.spacing value="S" />
      <.wrap>
        <Button.dynamic {@data_donation_cleanup_button} />
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
