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
    * `{:below_threshold, _}` — a flash, no modal.
    * any other error — `:verify` variant too: the payouts tab is the only
      actionable next step, so never dead-end on "try again later".

  Errors from `Fund.Public.request_payout/2` — after confirming, and on retry —
  are routed the same way: threshold misses flash, anything else swaps the modal
  to the `:verify` variant rather than a generic "try again later".

  All i18n is resolved by `Systems.Home.PageBuilder`; this view only renders
  the supplied `labels`.
  """
  use CoreWeb, :live_component_fabric

  alias Frameworks.Pixel
  alias Frameworks.Pixel.Button
  require Logger

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
          donating_cents: donating_cents,
          donated_cents: donated_cents,
          payout_status: payout_status,
          donate_enabled?: donate_enabled?,
          labels: labels,
          user: user,
          payout_currency: payout_currency
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
        donating_cents: donating_cents,
        donated_cents: donated_cents,
        payout_status: payout_status,
        donate_enabled?: donate_enabled?,
        labels: labels,
        user: user,
        payout_currency: payout_currency
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

  def compose(:handoff_modal, %{handoff_mode: :awaiting, labels: labels}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          title: labels.payout_awaiting_title,
          body: labels.payout_awaiting_body,
          confirm_label: labels.payout_awaiting_confirm,
          cancel_label: nil
        }
      }
    }
  end

  # The waiver (MS.4): confirming here gives up the right to a payout, so the
  # body must say so and the confirm label must not read like a plain "OK".
  def compose(:handoff_modal, %{handoff_mode: :donate, labels: labels}) do
    %{
      module: Pixel.ConfirmationModal,
      params: %{
        assigns: %{
          title: labels.donate_handoff_title,
          body: labels.donate_handoff_body,
          confirm_label: labels.donate_handoff_confirm,
          cancel_label: labels.payout_handoff_cancel
        }
      }
    }
  end

  @impl true
  def handle_event(
        "request_payout",
        _params,
        %{assigns: %{user: user, payout_currency: payout_currency, labels: labels}} = socket
      ) do
    case Fund.Public.prepare_payout(user, payout_currency) do
      :ok ->
        {:noreply, present_handoff(socket, :payout)}

      {:error, {:kyc_required, _source, _url}} ->
        {:noreply, present_handoff(socket, :verify)}

      {:error, :awaiting_verification} ->
        {:noreply, present_handoff(socket, :awaiting)}

      {:error, {:below_threshold, _cents}} ->
        {:noreply, socket |> Flash.push_error(labels.payout_below_threshold)}

      {:error, _reason} ->
        {:noreply, present_handoff(socket, :verify)}
    end
  end

  # A stranded payout is already past the bank-verification handoff, so the retry
  # resumes it directly. request_payout resumes an unresolved payout rather than
  # starting a new one, so the currency only satisfies the signature here.
  @impl true
  def handle_event(
        "retry_payout",
        _params,
        %{assigns: %{user: user, payout_currency: payout_currency}} = socket
      ) do
    case Fund.Public.request_payout(user, payout_currency) do
      {:ok, _result} ->
        send(self(), :payout_completed)
        {:noreply, socket}

      error ->
        {:noreply, socket |> handle_payout_error(error) |> refresh_totals(user)}
    end
  end

  # No provider call before the modal: a donation needs no merchant, no bank
  # account and no KYC, so there is nothing to prepare.
  #
  # Guarded on the server-set :opp_phase_3 assign, not just the hidden button —
  # a client can send the event either way, and confirming it waives a right.
  @impl true
  def handle_event("donate", _params, %{assigns: %{donate_enabled?: true}} = socket) do
    {:noreply, present_handoff(socket, :donate)}
  end

  @impl true
  def handle_event("donate", _params, socket), do: {:noreply, socket}

  # MUST stay above the unguarded payout "confirmed" clause below, which would
  # otherwise swallow this and fire a payout instead of a donation.
  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :handoff_modal}},
        %{
          assigns: %{
            handoff_mode: :donate,
            donate_enabled?: true,
            user: user,
            payout_currency: payout_currency
          }
        } = socket
      ) do
    socket = hide_modal(socket, :handoff_modal)

    # MS.8: the refreshed card — approved at zero, the donated total shown — is
    # the confirmation. Nothing to navigate to, and nothing to refresh here
    # either: request_donation dispatches {:fund_rewards_summary, :updated}, so
    # Observatory pushes the new totals into this card by itself.
    {:noreply, flash_donation_result(socket, Fund.Public.request_donation(user, payout_currency))}
  end

  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :handoff_modal}},
        %{assigns: %{handoff_mode: :awaiting}} = socket
      ) do
    # Awaiting-verification info modal: "OK" only dismisses; the participant
    # can't do anything but wait for the provider's review to complete.
    {:noreply, hide_modal(socket, :handoff_modal)}
  end

  # Guarded on :payout, not a catch-all: two modes now trigger a money movement
  # from this same event, so an unmatched one must never fall through into the
  # wrong one. Anything not handled above lands on the no-op clause below.
  @impl true
  def handle_event(
        "confirmed",
        %{source: %{name: :handoff_modal}},
        %{assigns: %{handoff_mode: :payout, user: user, payout_currency: payout_currency}} =
          socket
      ) do
    socket = hide_modal(socket, :handoff_modal)

    case Fund.Public.request_payout(user, payout_currency) do
      {:ok, _result} ->
        # Redirecting here is forbidden — this handler runs inside the
        # component's update/2 lifecycle (Fabric delivers the modal event via
        # send_update). Hand off to Home.Page, which redirects from handle_info.
        send(self(), :payout_completed)
        {:noreply, socket}

      error ->
        # Refresh: a lost lock-race hides the now-stale payout button.
        {:noreply, socket |> handle_payout_error(error) |> refresh_totals(user)}
    end
  end

  # :verify confirms via an external link and never reaches the server; a
  # :donate confirm with the feature off lands here too. Dismiss, do nothing.
  @impl true
  def handle_event("confirmed", %{source: %{name: :handoff_modal}}, socket) do
    {:noreply, hide_modal(socket, :handoff_modal)}
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: :handoff_modal}}, socket) do
    {:noreply, hide_modal(socket, :handoff_modal)}
  end

  @impl true
  def handle_modal_closed(socket, :handoff_modal), do: socket

  defp handle_payout_error(
         %{assigns: %{labels: labels}} = socket,
         {:error, {:below_threshold, _cents}}
       ),
       do: Flash.push_error(socket, labels.payout_below_threshold)

  defp handle_payout_error(socket, {:error, _reason}), do: present_handoff(socket, :verify)

  defp flash_donation_result(%{assigns: %{labels: labels}} = socket, {:ok, _donation}),
    do: Flash.push_info(socket, labels.donate_thanks)

  # The charge may well have gone through: the rewards stay :donating and the
  # card already says so, so telling the participant to try again would be both
  # wrong and impossible (their approved balance is now zero).
  defp flash_donation_result(
         %{assigns: %{labels: labels}} = socket,
         {:error, {:opp_uncertain, _}}
       ),
       do: Flash.push_info(socket, labels.donate_pending)

  defp flash_donation_result(%{assigns: %{labels: labels}} = socket, error) do
    Logger.warning("[RewardsSummaryView] donation failed: #{inspect(error)}")
    Flash.push_error(socket, labels.donate_failed)
  end

  defp present_handoff(socket, mode) do
    socket
    |> assign(handoff_mode: mode)
    |> compose_child(:handoff_modal)
    |> show_modal(:handoff_modal, :compact)
  end

  defp refresh_totals(%{assigns: %{payout_currency: payout_currency}} = socket, user) do
    %{
      pending_cents: pending_cents,
      approved_cents: approved_cents,
      rejected_cents: rejected_cents,
      donating_cents: donating_cents,
      donated_cents: donated_cents
    } = Fund.Public.summarize_rewards(user, payout_currency)

    assign(socket,
      pending_cents: pending_cents,
      approved_cents: approved_cents,
      rejected_cents: rejected_cents,
      donating_cents: donating_cents,
      donated_cents: donated_cents,
      payout_status: Fund.Public.payout_status(user)
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

      <div class="flex flex-col md:flex-row gap-16">
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
          donate_button_label={@labels.donate_button}
          payout_enabled?={@approved_cents >= Fund.Public.payout_threshold_cents()}
          donate_enabled?={@donate_enabled? and @approved_cents > 0}
          target={@myself}
        />
        <%= if @rejected_cents > 0 do %>
          <.column
            pill_label={@labels.rejected_pill}
            pill_color="bg-delete"
            amount_cents={@rejected_cents}
          />
        <% end %>
      </div>
      <.payout_status_section status={@payout_status} labels={@labels} target={@myself} />
      <.donation_section
        donating_cents={@donating_cents}
        donated_cents={@donated_cents}
        labels={@labels}
      />
    </div>
    """
  end

  attr(:donating_cents, :integer, required: true)
  attr(:donated_cents, :integer, required: true)
  attr(:labels, :map, required: true)

  # Donated rewards, like locked ones, show in no column. Deliberately not gated
  # on donating_cents == 0 in the Donate button above: a donation stuck awaiting
  # manual resolution must not lock the participant out of donating later.
  defp donation_section(%{donating_cents: cents} = assigns) when cents > 0 do
    ~H"""
    <div class="mt-6 text-bodysmall font-body text-grey2" data-testid="donation-in-progress">
      <%= @labels.donate_in_progress %>
    </div>
    """
  end

  defp donation_section(%{donated_cents: cents} = assigns) when cents > 0 do
    ~H"""
    <div class="mt-6 text-bodysmall font-body text-grey2" data-testid="donation-total">
      <%= @labels.donated_total %> <%= CurrencyHelpers.format_cents(@donated_cents) %>
    </div>
    """
  end

  defp donation_section(assigns), do: ~H""

  attr(:status, :atom, required: true)
  attr(:labels, :map, required: true)
  attr(:target, :any, required: true)

  # Surfaces a payout the reward columns can't: its rewards are locked, so they
  # show in no bucket. :retryable is the only state the participant can act on.
  defp payout_status_section(%{status: :retryable} = assigns) do
    ~H"""
    <div class="mt-6" data-testid="payout-retry">
      <Button.dynamic
        action={%{type: :send, event: "retry_payout", target: @target}}
        face={%{type: :link, text: @labels.payout_retry_button}}
        testid="payout-retry-button"
      />
    </div>
    """
  end

  defp payout_status_section(%{status: :in_progress} = assigns) do
    ~H"""
    <div class="mt-6 text-bodysmall font-body text-grey2" data-testid="payout-in-progress">
      <%= @labels.payout_in_progress %>
    </div>
    """
  end

  defp payout_status_section(%{status: :manual} = assigns) do
    ~H"""
    <div class="mt-6 text-bodysmall font-body text-grey2" data-testid="payout-manual">
      <%= @labels.payout_manual %>
    </div>
    """
  end

  defp payout_status_section(%{status: :none} = assigns), do: ~H""

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
  attr(:donate_button_label, :string, required: true)
  attr(:payout_enabled?, :boolean, required: true)
  attr(:donate_enabled?, :boolean, required: true)
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
      <%= if @payout_enabled? or @donate_enabled? do %>
        <div class="self-start flex flex-col gap-1">
          <%= if @payout_enabled? do %>
            <Button.dynamic
              action={%{type: :send, event: "request_payout", target: @target}}
              face={%{type: :link, text: @payout_button_label}}
              testid="payout-button"
            />
          <% end %>
          <%= if @donate_enabled? do %>
            <Button.dynamic
              action={%{type: :send, event: "donate", target: @target}}
              face={%{type: :link, text: @donate_button_label}}
              testid="donate-button"
            />
          <% end %>
        </div>
      <% else %>
        <div class="text-bodysmall font-body text-grey2">
          <%= @caption %>
        </div>
      <% end %>
    </div>
    """
  end
end
