defmodule Systems.Assignment.PayoutModal do
  @moduledoc """
  Modal that lets a researcher resolve pending pay-outs for an assignment.
  Composed via `compose_child(:payout_modal) |> show_modal(:payout_modal, :sheet)`.

  All data access, transformation and i18n live in
  `Systems.Assignment.PayoutModalBuilder`; this component only renders the
  view model and handles events (delegating mutations to `Assignment.Public`).

  Two tabs: `:waiting` (default) lists rewards in `:pending_approval` with
  per-row Decline expansion + bulk "Pay out all"; `:overview` shows historical
  approvals + rejections (UI lands in commit C).
  """
  use CoreWeb, :live_component

  require Logger

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  alias Systems.Assignment
  alias Systems.Assignment.PayoutModalBuilder, as: Builder

  @impl true
  def update(%{id: id, assignment_id: assignment_id}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment_id: assignment_id,
        active_tab: :waiting,
        declining_task_id: nil,
        decline_reason: "",
        search_query: "",
        error: nil
      )
      |> assign_vm()
    }
  end

  defp assign_vm(%{assigns: %{assignment_id: assignment_id} = assigns} = socket) do
    state =
      Map.take(assigns, [
        :active_tab,
        :declining_task_id,
        :decline_reason,
        :search_query,
        :error
      ])

    assign(socket, vm: Builder.view_model(assignment_id, state))
  end

  @impl true
  def handle_event("update_search", %{"value" => query}, socket) do
    {:noreply, socket |> assign(search_query: query) |> assign_vm()}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(active_tab: Builder.resolve_tab(tab)) |> assign_vm()}
  end

  @impl true
  def handle_event("pay_out_all", _, %{assigns: %{vm: %{assignment: assignment}}} = socket) do
    error =
      case Assignment.Public.bulk_approve_pending_payouts(assignment) do
        {:ok, _count} ->
          nil

        {:error, reason} ->
          Logger.warning("[PayoutModal] bulk approve failed: #{inspect(reason)}")
          :pay_out_all
      end

    {:noreply,
     socket
     |> assign(declining_task_id: nil, decline_reason: "", error: error)
     |> assign_vm()}
  end

  @impl true
  def handle_event("expand_decline", %{"task-id" => task_id}, socket) do
    {:noreply,
     socket
     |> assign(declining_task_id: String.to_integer(task_id), decline_reason: "", error: nil)
     |> assign_vm()}
  end

  @impl true
  def handle_event("cancel_decline", _, socket) do
    {:noreply,
     socket |> assign(declining_task_id: nil, decline_reason: "", error: nil) |> assign_vm()}
  end

  @impl true
  def handle_event("update_reason", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, decline_reason: reason)}
  end

  @impl true
  def handle_event(
        "submit_decline",
        _,
        %{
          assigns: %{
            vm: %{assignment: assignment},
            declining_task_id: task_id,
            decline_reason: reason
          }
        } = socket
      )
      when is_integer(task_id) do
    {declining_task_id, error} =
      case Assignment.Public.reject_task_by_id(assignment, task_id, %{
             category: :other,
             message: reason
           }) do
        {:ok, _} ->
          {nil, nil}

        error ->
          Logger.warning("[PayoutModal] reject_task #{task_id} failed: #{inspect(error)}")
          {task_id, :decline}
      end

    {:noreply,
     socket
     |> assign(declining_task_id: declining_task_id, decline_reason: "", error: error)
     |> assign_vm()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="payout-modal">
      <%= if @vm.error do %>
        <div
          class="mb-6 px-4 py-3 rounded bg-warning text-white text-bodymedium font-body"
          data-testid="payout-error"
        >
          <%= error_message(@vm) %>
        </div>
      <% end %>
      <div class="flex justify-center pb-6">
        <div class="inline-flex p-1 rounded-full bg-grey5">
          <button
            type="button"
            phx-click="switch_tab"
            phx-value-tab="waiting"
            phx-target={@myself}
            data-testid="payout-tab-waiting"
            class={tab_segment_class(@vm.active_tab == :waiting)}
          >
            <%= @vm.labels.tab_waiting %>
          </button>
          <button
            type="button"
            phx-click="switch_tab"
            phx-value-tab="overview"
            phx-target={@myself}
            data-testid="payout-tab-overview"
            class={tab_segment_class(@vm.active_tab == :overview)}
          >
            <%= @vm.labels.tab_overview %>
          </button>
        </div>
      </div>
      <div class="border-b border-grey4 mb-6" />
      <%= if @vm.active_tab == :waiting do %>
        <.waiting_tab
          payouts={@vm.payouts}
          count={@vm.count}
          search_query={@vm.search_query}
          declining_task_id={@vm.declining_task_id}
          decline_reason={@vm.decline_reason}
          labels={@vm.labels}
          myself={@myself}
        />
      <% else %>
        <.overview_tab labels={@vm.labels} />
      <% end %>
    </div>
    """
  end

  defp error_message(%{error: :pay_out_all, labels: %{pay_out_all_error: msg}}), do: msg
  defp error_message(%{error: :decline, labels: %{decline_error: msg}}), do: msg
  defp error_message(%{labels: %{decline_error: msg}}), do: msg

  attr(:payouts, :list, required: true)
  attr(:count, :integer, required: true)
  attr(:search_query, :string, default: "")
  attr(:declining_task_id, :integer, default: nil)
  attr(:decline_reason, :string, default: "")
  attr(:labels, :map, required: true)
  attr(:myself, :any, required: true)

  defp waiting_tab(assigns) do
    ~H"""
    <div data-testid="payout-waiting-tab">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @labels.waiting_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="payout-waiting-count">
          <%= @count %>
        </span>
      </div>

      <div class="mb-6">
        <button
          type="button"
          phx-click="pay_out_all"
          phx-target={@myself}
          disabled={@count == 0}
          data-testid="pay-out-all-button"
          class={pay_out_all_class(@count > 0)}
        >
          <span
            class="inline-flex items-center justify-center w-6 h-6 rounded-full border-2 border-white text-white"
            style="font-size: 11px; line-height: 1;"
          >
            €
          </span>
          <span><%= @labels.pay_out_all %></span>
        </button>
      </div>

      <form phx-change="update_search" phx-target={@myself} class="mb-2">
        <div class="relative">
          <input
            type="text"
            name="value"
            value={@search_query}
            placeholder={@labels.search_placeholder}
            class="w-full border border-grey3 rounded px-4 py-2 pr-10 text-bodymedium font-body focus:outline-none focus:border-primary"
            data-testid="payout-search"
          />
          <svg
            class="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-primary pointer-events-none"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle cx="11" cy="11" r="7" />
            <path d="m21 21-4.3-4.3" />
          </svg>
        </div>
      </form>

      <%= if @count == 0 do %>
        <div class="text-bodymedium font-body text-grey2 py-8" data-testid="payout-empty">
          <%= @labels.waiting_empty %>
        </div>
      <% else %>
        <div class="flex flex-col">
          <%= for row <- @payouts do %>
            <.payout_row
              row={row}
              declining?={@declining_task_id == row.task_id}
              decline_reason={@decline_reason}
              labels={@labels}
              myself={@myself}
            />
          <% end %>
        </div>

        <div class="mt-6 flex items-center justify-between text-bodysmall font-body text-grey2" data-testid="payout-pagination">
          <div class="flex items-center gap-2">
            <button
              type="button"
              class="w-8 h-8 flex items-center justify-center rounded text-grey3 cursor-default"
              disabled
              aria-label="previous"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M15 18l-6-6 6-6" />
              </svg>
            </button>
            <span class="w-8 h-8 flex items-center justify-center rounded bg-primary text-white text-button font-button">1</span>
            <button
              type="button"
              class="w-8 h-8 flex items-center justify-center rounded text-grey3 cursor-default"
              disabled
              aria-label="next"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M9 18l6-6-6-6" />
              </svg>
            </button>
          </div>
          <span><%= @labels.pagination_single %></span>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:row, :map, required: true)
  attr(:declining?, :boolean, default: false)
  attr(:decline_reason, :string, default: "")
  attr(:labels, :map, required: true)
  attr(:myself, :any, required: true)

  defp payout_row(assigns) do
    ~H"""
    <div class="py-3" data-testid={"payout-row-#{@row.task_id}"}>
      <div class="flex items-center justify-between">
        <span class="text-bodymedium font-body">
          <%= @labels.subject_label %>
          <%= @row.member_public_id || @row.task_id %>
        </span>
        <%= if @declining? do %>
          <a
            phx-click="cancel_decline"
            phx-target={@myself}
            class="text-primary cursor-pointer hover:underline"
            data-testid={"cancel-decline-#{@row.task_id}"}
          >
            <%= @labels.cancel %>
          </a>
        <% else %>
          <a
            phx-click="expand_decline"
            phx-value-task-id={@row.task_id}
            phx-target={@myself}
            class="text-primary cursor-pointer hover:underline"
            data-testid={"decline-#{@row.task_id}"}
          >
            <%= @labels.decline_link %>
          </a>
        <% end %>
      </div>

      <%= if @declining? do %>
        <div class="mt-3">
          <form phx-submit="submit_decline" phx-change="update_reason" phx-target={@myself}>
            <label class="block text-bodymedium font-body font-bold mb-1">
              <%= @labels.decline_reason_label %>
            </label>
            <textarea
              name="reason"
              rows="3"
              class="w-full border border-grey3 rounded p-2 text-bodymedium font-body"
              data-testid={"decline-reason-#{@row.task_id}"}
            ><%= @decline_reason %></textarea>
            <div class="mt-3">
              <Button.dynamic
                action={%{type: :submit}}
                face={%{
                  type: :primary,
                  label: @labels.decline_submit
                }}
                testid={"submit-decline-#{@row.task_id}"}
              />
            </div>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:labels, :map, required: true)

  defp overview_tab(assigns) do
    ~H"""
    <div data-testid="payout-overview-tab">
      <Text.title3>
        <%= @labels.overview_heading %>
      </Text.title3>
      <.spacing value="S" />
      <Text.body color="text-grey2">
        <%= @labels.overview_coming_soon %>
      </Text.body>
    </div>
    """
  end

  defp tab_segment_class(true),
    do: "px-5 py-2 rounded-full bg-primary text-white text-button font-button"

  defp tab_segment_class(false),
    do:
      "px-5 py-2 rounded-full bg-transparent text-grey2 text-button font-button hover:text-grey1"

  defp pay_out_all_class(true),
    do:
      "inline-flex items-center gap-3 px-5 py-2 rounded bg-primary hover:bg-primary/90 text-white text-button font-button"

  defp pay_out_all_class(false),
    do:
      "inline-flex items-center gap-3 px-5 py-2 rounded bg-primary text-white text-button font-button opacity-50 cursor-not-allowed"
end
