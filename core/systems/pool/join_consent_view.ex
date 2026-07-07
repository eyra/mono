defmodule Systems.Pool.JoinConsentView do
  @moduledoc """
  Informed-consent view for joining a pool.

  Renders a short "would you like to join this pool?" prompt with accept and
  decline actions. Publishes `:accept` on accept and `:decline` on decline;
  the parent handles the actual join (typically by dispatching
  `{:account, :post_signup}` with `"join_pool:<slug>"`) and manages its own
  container UI (close the modal, advance the onboarding step, …).

  Soft consent only — no signed record is created. If the pool ever needs a
  proper signed agreement, wrap `Systems.Consent.ClickWrapView` instead.
  """
  use CoreWeb.LiveForm
  import LiveNest.Event.Publisher, only: [publish_event: 2]

  @impl true
  def update(%{id: id, pool: pool}, socket) do
    {
      :ok,
      socket
      |> assign(id: id, pool: pool)
      |> update_buttons()
    }
  end

  defp update_buttons(%{assigns: %{myself: myself, pool: pool}} = socket) do
    accept_button = %{
      action: %{type: :send, event: "accept", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-pool", "join_consent.accept.button", pool_name: pool.name)
      },
      testid: "pool-join-consent-accept-button"
    }

    decline_button = %{
      action: %{type: :send, event: "decline", target: myself},
      face: %{
        type: :label,
        label: dgettext("eyra-pool", "join_consent.decline.button")
      },
      testid: "pool-join-consent-decline-button"
    }

    assign(socket, buttons: [accept_button, decline_button])
  end

  @impl true
  def handle_event("accept", _payload, socket) do
    {:noreply, socket |> publish_event(:accept)}
  end

  @impl true
  def handle_event("decline", _payload, socket) do
    {:noreply, socket |> publish_event(:decline)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="pool-join-consent-view">
      <Text.title2>
        <%= dgettext("eyra-pool", "join_consent.title", pool_name: @pool.name) %>
      </Text.title2>
      <.spacing value="M" />
      <Text.body>
        <%= dgettext("eyra-pool", "join_consent.body", pool_name: @pool.name) %>
      </Text.body>
      <.spacing value="L" />
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </div>
    """
  end
end
