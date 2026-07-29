defmodule Systems.Assignment.ContributionsConfirmedView do
  @moduledoc """
  "Confirmed" section of the Contributions tab. Read-only history of
  contributions the researcher has already confirmed (approved) — the
  normal end state (~99% of contributions).

  Rendered as a plain `Phoenix.LiveComponent` inside the
  `ContributionsView` embedded LiveView.
  """
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text

  alias Systems.Assignment
  alias Systems.Assignment.CurrencyHelpers

  @impl true
  def update(%{id: id, assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(id: id, assignment: assignment)
      |> update_view_model()
    }
  end

  defp update_view_model(%{assigns: %{assignment: assignment}} = socket) do
    rows = Assignment.Public.list_confirmed_contributions(assignment)

    vm = %{
      rows: rows,
      count: length(rows),
      labels: labels()
    }

    assign(socket, vm: vm)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="contributions-confirmed">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @vm.labels.overview_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-confirmed-count">
          <%= @vm.count %>
        </span>
      </div>

      <%= if @vm.count == 0 do %>
        <div class="text-bodymedium font-body text-grey2 pb-6" data-testid="contributions-confirmed-empty">
          <%= @vm.labels.overview_empty %>
        </div>
      <% else %>
        <table class="w-full text-bodymedium font-body">
          <tbody>
            <%= for row <- @vm.rows do %>
              <.overview_row row={row} labels={@vm.labels} />
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)

  defp overview_row(assigns) do
    ~H"""
    <tr data-testid={"contributions-confirmed-row-#{@row.reward_id}"}>
      <td class="py-3">
        <%= @labels.subject_label %>
        <%= @row.member_public_id || @row.reward_id %>
      </td>
      <td class="py-3 text-right text-grey2" data-testid={"contributions-confirmed-amount-#{@row.reward_id}"}>
        <%= CurrencyHelpers.format_cents(@row.amount) %>
      </td>
      <td class="py-3 text-right text-grey2" data-testid={"contributions-confirmed-date-#{@row.reward_id}"}>
        <%= Timestamp.format_date!(@row.paid_at) %>
      </td>
    </tr>
    """
  end

  defp labels do
    %{
      overview_heading: dgettext("eyra-assignment", "payout.overview.heading"),
      overview_empty: dgettext("eyra-assignment", "payout.overview.empty"),
      subject_label: dgettext("eyra-assignment", "payout.subject_label")
    }
  end
end
