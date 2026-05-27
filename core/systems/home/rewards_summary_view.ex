defmodule Systems.Home.RewardsSummaryView do
  @moduledoc """
  "Vergoedingen" card on the participant home page. Three columns — pending,
  approved, rejected — each showing the per-status amount (cents) and a label.

  The approved column also exposes a "Uitbetalen" (payout) button when the
  participant has any `:approved` rewards. Clicking it invokes
  `Systems.Fund.Public.request_payout/1` and renders the outcome as a flash.

  All i18n is resolved by `Systems.Home.PageBuilder`; this view only renders
  the supplied `labels`.
  """
  use CoreWeb, :live_component

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
    }
  end

  @impl true
  def handle_event("request_payout", _params, %{assigns: %{user: user, labels: labels}} = socket) do
    case Fund.Public.request_payout(user) do
      {:ok, _result} ->
        {:noreply, socket |> Flash.push_info(labels.payout_success) |> refresh_totals(user)}

      {:error, :no_merchant} ->
        {:noreply, socket |> Flash.push_error(labels.payout_no_merchant)}

      {:error, {:below_threshold, _cents}} ->
        {:noreply, socket |> Flash.push_error(labels.payout_below_threshold)}

      {:error, {:opp_failed, _reason}} ->
        {:noreply, socket |> Flash.push_error(labels.payout_failed)}
    end
  end

  defp refresh_totals(socket, user) do
    %{pending_cents: p, approved_cents: a, rejected_cents: r} =
      Fund.Public.summarize_rewards(user)

    assign(socket, pending_cents: p, approved_cents: a, rejected_cents: r)
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
