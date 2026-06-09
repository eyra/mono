defmodule Systems.Home.RewardsSummaryView do
  @moduledoc """
  "Vergoedingen" card on the participant home page. Three columns — pending,
  approved, rejected — each showing the per-status amount (cents) and a label.

  The approved column also exposes a "Uitbetalen" (payout) button when the
  participant has any `:approved` rewards. Clicking it runs
  `Fund.Public.prepare_payout/1` and presents the MS.6 handoff via the shared
  `Frameworks.Pixel.ConfirmationModal` (`show_modal(:handoff_modal, :compact)`):

    * `:ok` — `:payout` variant ("you are leaving Next to be sent to OPP");
      confirming fires `Fund.Public.request_payout/1`.
    * `{:kyc_required, url}` — `:kyc` variant; confirming redirects to OPP to
      complete onboarding.
    * `{:below_threshold, _}` / other errors — a flash, no modal.

  All i18n is resolved by `Systems.Home.PageBuilder`; this view only renders
  the supplied `labels`.
  """
  use CoreWeb, :live_component

  alias Frameworks.Pixel
  alias Frameworks.Pixel.Flash
  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Fund

  @impl true
  def update(
        %{
          pending_cents: pending_cents,
          approved_cents: approved_cents,
          rejected_cents: rejected_cents,
          labels: labels,
          user: user
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        pending_cents: pending_cents,
        approved_cents: approved_cents,
        rejected_cents: rejected_cents,
        labels: labels,
        user: user
      )
      |> assign_new(:handoff_mode, fn -> :payout end)
      |> assign_new(:kyc_overview_url, fn -> nil end)
    }
  end

  @impl true
  def compose(:handoff_modal, %{handoff_mode: :kyc, kyc_overview_url: url, labels: labels})
      when is_binary(url) do
    # KYC confirm is an external link to OPP — NOT a server "confirm" event.
    # A redirect issued from the parent-event (send_update) cycle would be
    # silently dropped, so the browser must navigate via a real anchor.
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          title: labels.payout_kyc_title,
          body: labels.payout_kyc_body,
          confirm_label: labels.payout_kyc_confirm,
          cancel_label: labels.payout_handoff_cancel,
          confirm_action: %{type: :http_get, to: url}
        }
      }
    }
  end

  def compose(:handoff_modal, %{handoff_mode: :payout, labels: labels}) do
    # Payout confirm is a standard "confirm" send event -> request_payout.
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          title: labels.payout_handoff_title,
          body: labels.payout_handoff_body,
          confirm_label: labels.payout_handoff_confirm,
          cancel_label: labels.payout_handoff_cancel
        }
      }
    }
  end

  @impl true
  def handle_event("request_payout", _params, %{assigns: %{user: user, labels: labels}} = socket) do
    case Fund.Public.prepare_payout(user) do
      :ok ->
        {:noreply, present_handoff(socket, :payout, nil)}

      {:error, {:kyc_required, kyc_url}} when is_binary(kyc_url) ->
        {:noreply, present_handoff(socket, :kyc, kyc_url)}

      {:error, {:below_threshold, _cents}} ->
        {:noreply, socket |> Flash.push_error(labels.payout_below_threshold)}

      # Covers {:error, :kyc_unavailable}, {:error, :no_merchant} and any
      # provider/network error — no handoff, just surface the failure.
      {:error, _reason} ->
        {:noreply, socket |> Flash.push_error(labels.payout_failed)}
    end
  end

  # Payout variant confirm (the KYC variant confirms via an external link, so
  # it never reaches the server). ConfirmationModal sends "confirmed" to its
  # parent; this runs inside a send_update cycle, so we must NOT rely on a
  # redirect here — only DB work + flash + assign, which propagate fine.
  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :handoff_modal}},
        %{assigns: %{user: user, labels: labels}} = socket
      ) do
    socket = hide_modal(socket, :handoff_modal)

    # Always refresh after the call: on success the locked balance drops to 0,
    # and on a lost lock-race (:lock_failed) the winner already moved the rewards
    # to :pending_payout — refreshing hides the now-stale balance + payout button
    # so the participant doesn't keep clicking a button that can only fail.
    case Fund.Public.request_payout(user) do
      {:ok, _result} ->
        {:noreply, socket |> Flash.push_info(labels.payout_success) |> refresh_totals(user)}

      {:error, {:below_threshold, _cents}} ->
        {:noreply,
         socket |> Flash.push_error(labels.payout_below_threshold) |> refresh_totals(user)}

      # {:opp_failed, _}, :no_merchant, :lock_failed, :kyc_unavailable, and a
      # drifted {:kyc_required, _} (rare) — surface a flash; the next click
      # re-evaluates and shows the KYC link.
      {:error, _reason} ->
        {:noreply, socket |> Flash.push_error(labels.payout_failed) |> refresh_totals(user)}
    end
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :handoff_modal}}, socket) do
    {:noreply, hide_modal(socket, :handoff_modal)}
  end

  @impl true
  def handle_modal_closed(socket, :handoff_modal), do: socket

  defp present_handoff(socket, mode, kyc_overview_url) do
    socket
    |> assign(handoff_mode: mode, kyc_overview_url: kyc_overview_url)
    |> compose_child(:handoff_modal)
    |> show_modal(:handoff_modal, :compact)
  end

  defp refresh_totals(socket, user) do
    %{
      pending_cents: pending_cents,
      approved_cents: approved_cents,
      rejected_cents: rejected_cents
    } = Fund.Public.summarize_rewards(user)

    assign(socket,
      pending_cents: pending_cents,
      approved_cents: approved_cents,
      rejected_cents: rejected_cents
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-2 border-grey4 rounded p-6" data-testid="rewards-summary">
      <Text.title2 margin="">
        <%= @labels.title %>
      </Text.title2>
      <.spacing value="M" />

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <.column
          pill_label={@labels.pending_pill}
          pill_color="bg-warning"
          amount_cents={@pending_cents}
          caption={@labels.pending_caption}
        />
        <.approved_column
          pill_label={@labels.approved_pill}
          amount_cents={@approved_cents}
          caption={@labels.approved_caption}
          payout_button_label={@labels.payout_button}
          payout_enabled?={@approved_cents > 0}
          target={@myself}
        />
        <.column
          pill_label={@labels.rejected_pill}
          pill_color="bg-delete"
          amount_cents={@rejected_cents}
        />
      </div>
    </div>
    """
  end

  attr(:pill_label, :string, required: true)
  attr(:pill_color, :string, required: true)
  attr(:amount_cents, :integer, required: true)
  attr(:caption, :string, default: nil)

  defp column(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <span class={"inline-flex self-start px-3 py-1 rounded-full text-white text-label font-label #{@pill_color}"}>
        <%= @pill_label %>
      </span>
      <div class="text-title3 font-title3 text-grey1">
        <%= CurrencyHelpers.format_cents(@amount_cents) %>
      </div>
      <%= if @caption do %>
        <div class="text-bodysmall font-body text-grey2">
          <%= @caption %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:pill_label, :string, required: true)
  attr(:amount_cents, :integer, required: true)
  attr(:caption, :string, required: true)
  attr(:payout_button_label, :string, required: true)
  attr(:payout_enabled?, :boolean, required: true)
  attr(:target, :any, required: true)

  defp approved_column(assigns) do
    ~H"""
    <div class="flex flex-col gap-2" data-testid="approved-column">
      <span class="inline-flex self-start px-3 py-1 rounded-full text-white text-label font-label bg-success">
        <%= @pill_label %>
      </span>
      <div class="text-title3 font-title3 text-grey1">
        <%= CurrencyHelpers.format_cents(@amount_cents) %>
      </div>
      <%= if @payout_enabled? do %>
        <button
          type="button"
          phx-click="request_payout"
          phx-target={@target}
          data-testid="payout-button"
          class="self-start text-button font-button text-primary hover:underline"
        >
          <%= @payout_button_label %>
        </button>
      <% end %>
      <div class="text-bodysmall font-body text-grey2">
        <%= @caption %>
      </div>
    </div>
    """
  end
end
