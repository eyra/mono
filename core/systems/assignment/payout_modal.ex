defmodule Systems.Assignment.PayoutModal do
  @moduledoc """
  Modal that lets a researcher resolve pending pay-outs for an assignment.
  Composed via `compose_child(:payout_modal) |> show_modal(:payout_modal, :sheet)`.

  All data access, transformation and i18n live in
  `Systems.Assignment.PayoutModalBuilder`; this component only renders the
  view model and owns local UI state (active tab, decline expansion,
  search query, error banner).

  Mutations (`pay_out_all`, `submit_decline`) do NOT run here — the button
  click and form submit fire the local shim clauses, which only bubble
  the event to the parent via `send_event(:parent, ...)`. The auth-gated
  parent (`Systems.Assignment.ParticipantsView`) owns the actual mutation.
  Composing this modal under any other parent gives the parent the choice
  whether to implement those events — with no such handler, no mutation.

  The parent signals the outcome back via `send_event(socket, :payout_modal,
  ...)`, which this component receives as `"post_pay_out_all"` /
  `"post_submit_decline"` events and uses to update the local error banner
  and refresh the view model.

  Two tabs: `:waiting` (default) lists rewards in `:pending_approval` with
  per-row Decline expansion + bulk "Pay out all"; `:overview` shows historical
  approvals + rejections (UI lands in commit C).
  """
  use CoreWeb, :live_component

  require Logger

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text

  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Assignment.PayoutModalBuilder, as: Builder

  @impl true
  def update(%{id: _id, search_query: %{query_string: query_string}}, socket) do
    {:ok, socket |> assign(search_query: query_string) |> assign_vm()}
  end

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
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(active_tab: Builder.resolve_tab(tab)) |> assign_vm()}
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

  # Shim: mutation is not performed here. The auth-gated parent
  # (ParticipantsView) owns the actual bulk-approve handler. This clause
  # just bubbles the event up so the parent can decide (auth by
  # construction — an unauthenticated parent that hasn't wired the handler
  # simply does nothing).
  @impl true
  def handle_event("pay_out_all", _, socket) do
    {:noreply, send_event(socket, :parent, "pay_out_all")}
  end

  # Shim: same rationale as pay_out_all. Task id + reason come from local
  # UI state (updated by expand_decline / update_reason) and are passed up
  # to the parent, which is the only place the reject actually runs.
  @impl true
  def handle_event(
        "submit_decline",
        _,
        %{assigns: %{declining_task_id: task_id, decline_reason: reason}} = socket
      )
      when is_integer(task_id) do
    {:noreply, send_event(socket, :parent, "submit_decline", %{task_id: task_id, reason: reason})}
  end

  # Result signal from the auth-gated parent after a bulk approve. Success
  # clears the decline UI and the error banner; failure keeps the modal state
  # and surfaces the error. Either way the view model re-fetches to reflect
  # whatever the mutation did (or didn't) change.
  @impl true
  def handle_event("post_pay_out_all", %{result: {:ok, _count}}, socket) do
    {:noreply,
     socket
     |> assign(declining_task_id: nil, decline_reason: "", error: nil)
     |> assign_vm()}
  end

  @impl true
  def handle_event("post_pay_out_all", %{result: {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> assign(declining_task_id: nil, decline_reason: "", error: :pay_out_all)
     |> assign_vm()}
  end

  # Result signal for a per-row decline. On success clear the decline UI; on
  # failure keep the decline expanded so the user can retry after seeing the
  # error banner.
  @impl true
  def handle_event("post_submit_decline", %{result: {:ok, _}}, socket) do
    {:noreply,
     socket
     |> assign(declining_task_id: nil, decline_reason: "", error: nil)
     |> assign_vm()}
  end

  @impl true
  def handle_event("post_submit_decline", %{result: {:error, _reason}}, socket) do
    {:noreply,
     socket
     |> assign(decline_reason: "", error: :decline)
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
          id={@id}
          payouts={@vm.payouts}
          count={@vm.count}
          search_query={@vm.search_query}
          declining_task_id={@vm.declining_task_id}
          decline_reason={@vm.decline_reason}
          labels={@vm.labels}
          myself={@myself}
        />
      <% else %>
        <.overview_tab
          id={@id}
          labels={@vm.labels}
          completed_payouts={@vm.completed_payouts}
          completed_count={@vm.completed_count}
          search_query={@vm.search_query}
          myself={@myself}
        />
      <% end %>
    </div>
    """
  end

  defp error_message(%{error: :pay_out_all, labels: %{pay_out_all_error: msg}}), do: msg
  defp error_message(%{error: :decline, labels: %{decline_error: msg}}), do: msg
  defp error_message(%{labels: %{decline_error: msg}}), do: msg

  attr(:id, :any, required: true)
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

      <div class="mb-2">
        <.live_component
          module={SearchBar}
          id={:payout_waiting_search_bar}
          query_string={@search_query}
          placeholder={@labels.search_placeholder}
          debounce="200"
          target={{__MODULE__, @id}}
        />
      </div>

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

  attr(:id, :any, required: true)
  attr(:labels, :map, required: true)
  attr(:completed_payouts, :list, required: true)
  attr(:completed_count, :integer, required: true)
  attr(:search_query, :string, required: true)
  attr(:myself, :any, required: true)

  defp overview_tab(assigns) do
    ~H"""
    <div data-testid="payout-overview-tab">
      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @labels.overview_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="payout-overview-count">
          <%= @completed_count %>
        </span>
      </div>

      <div class="mb-2">
        <.live_component
          module={SearchBar}
          id={:payout_overview_search_bar}
          query_string={@search_query}
          placeholder={@labels.search_placeholder}
          debounce="200"
          target={{__MODULE__, @id}}
        />
      </div>

      <%= if @completed_count == 0 do %>
        <div class="text-bodymedium font-body text-grey2 py-8" data-testid="payout-overview-empty">
          <%= @labels.overview_empty %>
        </div>
      <% else %>
        <div class="flex flex-col">
          <%= for row <- @completed_payouts do %>
            <.overview_row row={row} labels={@labels} />
          <% end %>
        </div>

        <div class="mt-6 flex items-center justify-between text-bodysmall font-body text-grey2" data-testid="payout-overview-pagination">
          <div class="flex items-center gap-2">
            <div class="opacity-40 pointer-events-none">
              <Button.Face.icon icon={:back} size="w-8 h-8" alt="previous" />
            </div>
            <span class="w-8 h-8 flex items-center justify-center rounded bg-primary text-white text-button font-button">1</span>
            <div class="opacity-40 pointer-events-none">
              <Button.Face.icon icon={:forward} size="w-8 h-8" alt="next" />
            </div>
          </div>
          <span><%= @labels.pagination_single %></span>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)

  defp overview_row(assigns) do
    ~H"""
    <div class="py-3 flex items-center justify-between" data-testid={"payout-overview-row-#{@row.reward_id}"}>
      <span class="text-bodymedium font-body">
        <%= @labels.subject_label %>
        <%= @row.member_public_id || @row.reward_id %>
      </span>
      <span class="flex items-center gap-6 text-bodymedium font-body text-grey2">
        <span data-testid={"payout-overview-amount-#{@row.reward_id}"}>
          <%= CurrencyHelpers.format_cents(@row.amount) %>
        </span>
        <span data-testid={"payout-overview-date-#{@row.reward_id}"}>
          <%= Timestamp.format_date!(@row.paid_at) %>
        </span>
      </span>
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
