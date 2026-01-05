defmodule Systems.Assignment.OnboardingConsentView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes

  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Systems.Assignment

  def dependencies(), do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Margin.y id={:page_top} />
        <Area.content>
          <Text.title2><%= @vm.title %></Text.title2>
          <.live_component {@vm.clickwrap_view} />
        </Area.content>
      </div>
    """
  end
end
