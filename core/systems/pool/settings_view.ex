defmodule Systems.Pool.SettingsView do
  @moduledoc """
  Embedded LiveView for the Settings tab on the Pool Admin page.

  Placeholder. Pool settings (name, target, currency, archive) currently
  live in the `Citizen.Pool.Form` modal; this tab will replace it.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Text
  alias Systems.Pool

  def dependencies(), do: [:pool_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{pool_id: pool_id}}) do
    Pool.Public.get!(pool_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="pool-settings-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.body><%= dgettext("eyra-pool", "settings.placeholder") %></Text.body>
      </Area.content>
    </div>
    """
  end
end
