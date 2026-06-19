defmodule Systems.Pool.ParticipantsView do
  @moduledoc """
  Embedded LiveView for the Participants tab on the Pool Admin page.

  Placeholder. The real participant list (email + signup date + activation
  state, filter chips, search, pagination) lands in the follow-up commit
  for issue 9925221382.
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
    <div data-testid="pool-participants-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.body><%= dgettext("eyra-pool", "participants.placeholder") %></Text.body>
      </Area.content>
    </div>
    """
  end
end
