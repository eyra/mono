defmodule Systems.Pool.JoinConsentView do
  @moduledoc """
  Informed-consent view for joining a pool.

  Renders a short "would you like to join this pool?" prompt with an
  Accept action. Publishes `:accept` on click; the parent handles the
  actual join and container UI (advance the onboarding step, close a
  modal, ...).

  No explicit decline action — users hit browser Back to exit, same
  convention as the auth identify/verify pages. Soft consent only —
  no signed record is created. If the pool ever needs a proper signed
  agreement, wrap `Systems.Consent.ClickWrapView` instead.
  """
  use CoreWeb.LiveForm
  import LiveNest.Event.Publisher, only: [publish_event: 2]

  @impl true
  def update(%{id: id, pool: pool} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        pool: pool,
        show_title: Map.get(assigns, :show_title, true)
      )
      |> update_accept_button()
    }
  end

  defp update_accept_button(%{assigns: %{myself: myself, pool: pool}} = socket) do
    accept_button = %{
      action: %{type: :send, event: "accept", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-pool", "join_consent.accept.button", pool_name: pool.name)
      },
      testid: "pool-join-consent-accept-button"
    }

    assign(socket, accept_button: accept_button)
  end

  @impl true
  def handle_event("accept", _payload, socket) do
    {:noreply, socket |> publish_event(:accept)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="pool-join-consent-view">
      <%= if @show_title do %>
        <Text.title2>
          <%= dgettext("eyra-pool", "join_consent.title", pool_name: @pool.name) %>
        </Text.title2>
        <.spacing value="M" />
      <% end %>
      <Text.body>
        <%= dgettext("eyra-pool", "join_consent.body", pool_name: @pool.name) %>
      </Text.body>
      <.spacing value="L" />
      <div class="flex flex-row gap-4">
        <Button.dynamic {@accept_button} />
      </div>
    </div>
    """
  end
end
