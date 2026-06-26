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
    * `{:kyc_required, _, _}` — `:verify` variant; the bank account isn't
      verified yet, so an info modal lets the participant close it or continue to
      the account page (`/user/account?tab=payouts`), where verification lives.
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
    }
  end

  @impl true
  def compose(:handoff_modal, %{handoff_mode: :payout, labels: labels}) do
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

  # Bank account not verified yet: an info modal that lets the participant close
  # it or continue to the account page (`/user/account?tab=payouts`) to verify.
  def compose(:handoff_modal, %{handoff_mode: :verify, labels: labels}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          title: labels.payout_verify_title,
          body: labels.payout_verify_body,
          confirm_label: labels.payout_verify_confirm,
          cancel_label: labels.payout_handoff_cancel,
          confirm_action: %{type: :http_get, to: ~p"/user/account?tab=payouts"}
        }
      }
    }
  end

  @impl true
  def handle_event("request_payout", _params, %{assigns: %{user: user, labels: labels}} = socket) do
    case Fund.Public.prepare_payout(user) do
      :ok ->
        {:noreply, present_handoff(socket, :payout)}

      {:error, {:kyc_required, _source, _url}} ->
        # Bank account not verified yet: show an info modal offering to continue
        # to the account page, where the "Uitbetalingen" tab handles verification.
        {:noreply, present_handoff(socket, :verify)}

      {:error, {:below_threshold, _cents}} ->
        {:noreply, socket |> Flash.push_error(labels.payout_below_threshold)}

      {:error, _reason} ->
        {:noreply, socket |> Flash.push_error(labels.payout_failed)}
    end
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :handoff_modal}},
        %{assigns: %{user: user}} = socket
      ) do
    socket = hide_modal(socket, :handoff_modal)

    case Fund.Public.request_payout(user) do
      {:ok, _result} ->
        # Redirecting here is forbidden — this handler runs inside the
        # component's update/2 lifecycle (Fabric delivers the modal event via
        # send_update). Hand off to Home.Page, which redirects from handle_info.
        send(self(), :payout_completed)
        {:noreply, socket}

      error ->
        # Refresh: a lost lock-race hides the now-stale payout button.
        {:noreply, socket |> flash_payout_result(error) |> refresh_totals(user)}
    end
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :handoff_modal}}, socket) do
    {:noreply, hide_modal(socket, :handoff_modal)}
  end

  @impl true
  def handle_modal_closed(socket, :handoff_modal), do: socket

  defp flash_payout_result(
         %{assigns: %{labels: labels}} = socket,
         {:error, {:below_threshold, _cents}}
       ),
       do: Flash.push_error(socket, labels.payout_below_threshold)

  defp flash_payout_result(%{assigns: %{labels: labels}} = socket, {:error, _reason}),
    do: Flash.push_error(socket, labels.payout_failed)

  defp present_handoff(socket, mode) do
    socket
    |> assign(handoff_mode: mode)
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
