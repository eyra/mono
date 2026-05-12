defmodule Systems.Home.RewardsSummaryView do
  @moduledoc """
  "Vergoedingen" card on the participant home page. Three columns: awaiting,
  approved (wallet balance), rejected — each with the amount and a per-status
  CTA. Bottom-right link opens the payments modal listing all reward history.
  """
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers

  @impl true
  def update(%{pending_cents: p, approved_cents: a, rejected_cents: r}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(
        pending_cents: p,
        approved_cents: a,
        rejected_cents: r
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border-2 border-grey4 rounded p-6" data-testid="rewards-summary">
      <Text.title2 margin="">
        <%= dgettext("eyra-fund", "rewards_summary.title") %>
      </Text.title2>
      <.spacing value="M" />

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <.column
          pill_label={dgettext("eyra-fund", "rewards_summary.pending.pill")}
          pill_color="bg-warning"
          amount_cents={@pending_cents}
          caption={dgettext("eyra-fund", "rewards_summary.pending.caption")}
        />
        <.column
          pill_label={dgettext("eyra-fund", "rewards_summary.approved.pill")}
          pill_color="bg-success"
          amount_cents={@approved_cents}
          caption={dgettext("eyra-fund", "rewards_summary.approved.threshold")}
        />
        <.column
          pill_label={dgettext("eyra-fund", "rewards_summary.rejected.pill")}
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
end
