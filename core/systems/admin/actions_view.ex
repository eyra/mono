defmodule Systems.Admin.ActionsView do
  use CoreWeb, :embedded_live_view
  use Core.FeatureFlags

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Observatory

  def dependencies(), do: []

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {
      :ok,
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
    <div data-testid="actions-view">
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2 data-testid="actions-title"><%= @vm.title %></Text.title2>

      <%= for {section, index} <- Enum.with_index(@vm.sections) do %>
        <div data-testid={"section-#{index}"}>
          <Text.title3 margin=""><%= section.title %></Text.title3>
          <.spacing value="S" />
          <%= for button <- section.buttons do %>
            <.wrap>
              <Button.dynamic {button} />
              <.spacing value="S" />
            </.wrap>
          <% end %>
          <.spacing value="XL" />
        </div>
      <% end %>

      <%= if feature_enabled?(:debug_expire_force) do %>
        <.wrap>
          <Button.dynamic {@vm.expire_force_button} data-testid="expire-force-button" />
        </.wrap>
      <% end %>
      </Area.content>
    </div>
    """
  end
end
