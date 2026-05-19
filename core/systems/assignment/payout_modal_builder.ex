defmodule Systems.Assignment.PayoutModalBuilder do
  @moduledoc """
  ViewBuilder for `Systems.Assignment.PayoutModal`.

  Owns all data access, transformation and i18n so the LiveComponent only
  renders blocks and handles events. Returns a self-contained view model
  including resolved `labels` (no `dgettext` in the view layer).
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  @tabs [:waiting, :overview]

  def tabs, do: @tabs

  # Explicit mapping: the tab is client-controlled, so never String.to_atom it.
  def resolve_tab(tab) when tab in ["waiting", :waiting], do: :waiting
  def resolve_tab(tab) when tab in ["overview", :overview], do: :overview
  def resolve_tab(_), do: :waiting

  def view_model(assignment_id, %{} = state) when is_integer(assignment_id) do
    assignment =
      Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))

    active_tab = resolve_tab(Map.get(state, :active_tab, :waiting))
    query = Map.get(state, :search_query, "")

    payouts =
      assignment
      |> Assignment.Public.list_pending_payouts()
      |> filter_payouts(query)

    %{
      assignment: assignment,
      active_tab: active_tab,
      search_query: query,
      payouts: payouts,
      count: length(payouts),
      declining_task_id: Map.get(state, :declining_task_id),
      decline_reason: Map.get(state, :decline_reason, ""),
      error: Map.get(state, :error),
      labels: labels()
    }
  end

  defp filter_payouts(payouts, query) when query in [nil, ""], do: payouts

  defp filter_payouts(payouts, query) do
    needle = String.downcase(query)

    Enum.filter(payouts, fn %{member_public_id: id} ->
      id
      |> to_string()
      |> String.downcase()
      |> String.contains?(needle)
    end)
  end

  defp labels do
    %{
      tab_waiting: dgettext("eyra-assignment", "payout.tab.waiting"),
      tab_overview: dgettext("eyra-assignment", "payout.tab.overview"),
      waiting_heading: dgettext("eyra-assignment", "payout.waiting.heading"),
      pay_out_all: dgettext("eyra-assignment", "payout.pay_out_all.button"),
      pay_out_all_error: dgettext("eyra-assignment", "payout.pay_out_all.error"),
      search_placeholder: dgettext("eyra-assignment", "payout.search.placeholder"),
      waiting_empty: dgettext("eyra-assignment", "payout.waiting.empty"),
      pagination_single: dgettext("eyra-assignment", "payout.pagination.single_page"),
      subject_label: dgettext("eyra-assignment", "payout.subject_label"),
      cancel: dgettext("eyra-ui", "cancel.button"),
      decline_link: dgettext("eyra-assignment", "payout.decline.link"),
      decline_reason_label: dgettext("eyra-assignment", "payout.decline.reason.label"),
      decline_submit: dgettext("eyra-assignment", "payout.decline.submit.button"),
      decline_error: dgettext("eyra-assignment", "payout.decline.error"),
      overview_heading: dgettext("eyra-assignment", "payout.overview.heading"),
      overview_coming_soon: dgettext("eyra-assignment", "payout.overview.coming_soon")
    }
  end
end
