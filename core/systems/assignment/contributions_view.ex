defmodule Systems.Assignment.ContributionsView do
  @moduledoc """
  "Contributions" tab of an assignment. Reviews participant contributions
  (fraud check) before pay-out. The tab is composed of two sections,
  each rendered as its own LiveComponent:

  - `Systems.Assignment.ContributionsPendingView` — awaiting review
  - `Systems.Assignment.ContributionsConfirmedView` — confirmed history

  This module is a thin embedded LiveView that just resolves the
  assignment and composes the two sub-views.
  """
  use CoreWeb, :embedded_live_view

  require Logger

  alias Frameworks.Pixel.Text
  alias Systems.Assignment

  @pending_id "contributions-pending"
  @decline_modal_id "decline-contribution-modal"

  def dependencies(), do: [:assignment_id, :title]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  # Auth-gated mutations. Sub-components bubble events up here (they run in
  # the same LV process, so a bare `send(self(), …)` reaches these handlers).
  # Composing a sub-component elsewhere without a matching parent handler
  # is a no-op — auth by construction.
  @impl true
  def handle_info(:confirm_all, %{assigns: %{model: assignment}} = socket) do
    result = Assignment.Public.confirm_all_pending_contributions(assignment)

    if match?({:error, _}, result) do
      Logger.warning("[ContributionsView] bulk approve failed: #{inspect(result)}")
    end

    send_update(Assignment.ContributionsPendingView,
      id: @pending_id,
      mutation_result: {:confirm_all, result}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:submit_decline, %{task_id: task_id, reason: reason}},
        %{assigns: %{model: assignment}} = socket
      )
      when is_integer(task_id) do
    result =
      Assignment.Public.reject_task_by_id(assignment, task_id, %{
        category: :other,
        message: reason
      })

    if match?({:error, _}, result) do
      Logger.warning("[ContributionsView] reject_task #{task_id} failed: #{inspect(result)}")
    end

    send_update(Assignment.ContributionsPendingView,
      id: @pending_id,
      mutation_result: {:submit_decline, result}
    )

    {:noreply, socket |> hide_decline_modal()}
  end

  # Pending sub-component asks the parent to open the decline modal. We build
  # the LiveNest modal here so the sub-component stays free of modal wiring.
  @impl true
  def handle_info({:show_decline_modal, row}, socket) do
    modal =
      LiveNest.Modal.prepare_live_component(
        @decline_modal_id,
        Assignment.DeclineContributionForm,
        params: [
          task_id: row.task_id,
          subject_label: subject_label(row)
        ],
        style: :compact
      )

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_info(:hide_decline_modal, socket) do
    {:noreply, socket |> hide_decline_modal()}
  end

  defp hide_decline_modal(socket) do
    modal = %LiveNest.Modal{element: %LiveNest.Element{id: @decline_modal_id}}
    hide_modal(socket, modal)
  end

  defp subject_label(%{member_public_id: member_public_id, task_id: task_id}) do
    id = member_public_id || task_id
    "#{dgettext("eyra-assignment", "payout.subject_label")} #{id}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div data-testid="contributions-view">
          <Text.title2><%= @vm.title %></Text.title2>
          <.spacing value="L" />
          <%= for {{_key, section}, index} <- Enum.with_index(@vm.sections) do %>
            <%= if index > 0 do %>
              <div class="border-t border-grey4 mb-8" />
            <% end %>
            <.live_component module={section.module} id={section.id} assignment={section.assignment} />
          <% end %>
        </div>
      </Area.content>
    </div>
    """
  end
end
