defmodule Systems.Home.RewardsSummaryView do
  @moduledoc """
  "Vergoedingen" card on the participant home page. Three columns — pending,
  approved, rejected — each showing the per-status amount (cents) and a label.

  All i18n is resolved by `Systems.Home.PageBuilder`; this view only renders
  the supplied `labels`.
  """
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers

  @impl true
  def update(
        %{
          pending_cents: pending_cents,
          approved_cents: approved_cents,
          rejected_cents: rejected_cents,
          labels: labels
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
        labels: labels
      )
    }
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
        <.column
          pill_label={@labels.approved_pill}
          pill_color="bg-success"
          amount_cents={@approved_cents}
          caption={@labels.approved_caption}
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
end
