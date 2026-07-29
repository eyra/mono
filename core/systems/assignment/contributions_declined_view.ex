defmodule Systems.Assignment.ContributionsDeclinedView do
  @moduledoc """
  "Declined" section of the Contributions tab. Read-only history of
  contributions the researcher has declined. Rendered only when there is
  at least one declined contribution; the parent view decides visibility.

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
    rows = Assignment.Public.list_declined_contributions(assignment)

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
    <div data-testid="contributions-declined">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @vm.labels.heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-declined-count">
          <%= @vm.count %>
        </span>
      </div>

      <table class="w-full text-bodymedium font-body">
        <tbody>
          <%= for row <- @vm.rows do %>
            <.declined_row row={row} labels={@vm.labels} />
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)

  defp declined_row(assigns) do
    ~H"""
    <tr data-testid={"contributions-declined-row-#{@row.reward_id}"}>
      <td class="py-3">
        <%= @labels.subject_label %>
        <%= @row.member_public_id || @row.reward_id %>
      </td>
      <td class="py-3 text-right text-grey2" data-testid={"contributions-declined-amount-#{@row.reward_id}"}>
        <%= CurrencyHelpers.format_cents(@row.amount) %>
      </td>
      <td class="py-3 text-right text-grey2" data-testid={"contributions-declined-date-#{@row.reward_id}"}>
        <%= Timestamp.format_date!(@row.rejected_at) %>
      </td>
    </tr>
    """
  end

  defp labels do
    %{
      heading: dgettext("eyra-assignment", "payout.declined.heading"),
      subject_label: dgettext("eyra-assignment", "payout.subject_label")
    }
  end
end
