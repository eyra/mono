defmodule Systems.Assignment.ContributionsPendingView do
  @moduledoc """
  "Pending" section of the Contributions tab. Lists rewards in
  `:pending_approval` for the researcher to confirm (fraud check) or
  decline. Confirm-all fires locally; the per-row decline opens a modal —
  both mutations run on the auth-gated parent (`ContributionsView`).

  Rendered as a plain `Phoenix.LiveComponent`.
  """
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  alias Systems.Assignment

  # Result signal from the parent LV after a mutation. Success clears the
  # error; failure surfaces it.
  @impl true
  def update(%{id: _id, mutation_result: {:confirm_all, result}}, socket) do
    error = if match?({:error, _}, result), do: :confirm_all
    {:ok, socket |> assign(error: error) |> update_view_model()}
  end

  @impl true
  def update(%{id: _id, mutation_result: {:submit_decline, {:ok, _}}}, socket) do
    {:ok, socket |> assign(error: nil) |> update_view_model()}
  end

  @impl true
  def update(%{id: _id, mutation_result: {:submit_decline, {:error, _}}}, socket) do
    {:ok, socket |> assign(error: :decline) |> update_view_model()}
  end

  @impl true
  def update(%{id: id, assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(id: id, assignment: assignment, error: nil)
      |> update_view_model()
    }
  end

  defp update_view_model(%{assigns: %{assignment: assignment} = assigns} = socket) do
    rows = Assignment.Public.list_pending_contributions(assignment)
    count = length(rows)
    labels = labels()

    vm = %{
      rows: rows,
      count: count,
      error: Map.get(assigns, :error),
      confirm_button: confirm_button(count, socket.assigns.myself, labels),
      labels: labels
    }

    assign(socket, vm: vm)
  end

  defp confirm_button(count, _myself, _labels) when count <= 0, do: nil

  defp confirm_button(_count, myself, labels) do
    %{
      action: %{type: :send, event: "confirm_all", target: myself},
      face: %{type: :primary, label: labels.confirm_all},
      testid: "confirm-all-button"
    }
  end

  # Shim: mutation runs on the auth-gated parent (`ContributionsView`), not
  # here. Live_components share the LV process, so `send(self(), …)` reaches
  # the parent LV's `handle_info/2` directly.
  @impl true
  def handle_event("confirm_all", _, socket) do
    send(self(), :confirm_all)
    {:noreply, socket}
  end

  # The decline flow lives in the parent LV — the modal is a LiveNest modal,
  # so we forward the row's context up and let the parent open it.
  @impl true
  def handle_event(
        "expand_decline",
        %{"item" => task_id_str},
        %{assigns: %{vm: %{rows: rows}}} = socket
      ) do
    task_id = String.to_integer(task_id_str)

    case Enum.find(rows, &(&1.task_id == task_id)) do
      nil ->
        {:noreply, socket}

      row ->
        send(self(), {:show_decline_modal, row})
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-[500px]" data-testid="contributions-pending">
      <%= if @vm.error do %>
        <div
          class="mb-6 px-4 py-3 rounded bg-warning text-white text-bodymedium font-body"
          data-testid="contributions-pending-error"
        >
          <%= error_message(@vm) %>
        </div>
      <% end %>

      <div class="flex items-baseline gap-2 mb-6">
        <Text.title3 margin="">
          <%= @vm.labels.waiting_heading %>
        </Text.title3>
        <span class="text-title3 font-title3 text-primary" data-testid="contributions-pending-count">
          <%= @vm.count %>
        </span>
      </div>

      <%= if @vm.confirm_button do %>
        <div class="mb-6">
          <Button.dynamic {@vm.confirm_button} />
        </div>
      <% end %>

      <%= if @vm.count == 0 do %>
        <div class="text-bodymedium font-body text-grey2 pb-6" data-testid="contributions-pending-empty">
          <%= @vm.labels.waiting_empty %>
        </div>
      <% else %>
        <table class="w-full text-bodymedium font-body mb-6">
          <tbody>
            <%= for row <- @vm.rows do %>
              <.payout_row row={row} labels={@vm.labels} myself={@myself} />
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp error_message(%{error: :confirm_all, labels: %{confirm_all_error: msg}}), do: msg
  defp error_message(%{error: :decline, labels: %{decline_error: msg}}), do: msg
  defp error_message(%{labels: %{decline_error: msg}}), do: msg

  attr(:row, :map, required: true)
  attr(:labels, :map, required: true)
  attr(:myself, :any, required: true)

  defp payout_row(assigns) do
    ~H"""
    <tr data-testid={"payout-row-#{@row.task_id}"}>
      <td class="py-3">
        <%= @labels.subject_label %>
        <%= @row.member_public_id || @row.task_id %>
      </td>
      <td class="py-3 text-grey2" data-testid={"tasks-finished-#{@row.task_id}"}>
        <%= dngettext("eyra-assignment", "payout.tasks_finished.one", "payout.tasks_finished.other", @row.finished_task_count, count: @row.finished_task_count) %>
      </td>
      <td class="py-3 text-right">
        <Button.dynamic
          action={%{type: :send, event: "expand_decline", item: to_string(@row.task_id), target: @myself}}
          face={%{
            type: :plain,
            icon: :reject,
            icon_align: :left,
            label: @labels.decline_link
          }}
          testid={"decline-#{@row.task_id}"}
        />
      </td>
    </tr>
    """
  end

  defp labels do
    %{
      waiting_heading: dgettext("eyra-assignment", "payout.waiting.heading"),
      confirm_all: dgettext("eyra-assignment", "payout.confirm_all.button"),
      confirm_all_error: dgettext("eyra-assignment", "payout.confirm_all.error"),
      waiting_empty: dgettext("eyra-assignment", "payout.waiting.empty"),
      subject_label: dgettext("eyra-assignment", "payout.subject_label"),
      decline_link: dgettext("eyra-assignment", "payout.decline.link"),
      decline_error: dgettext("eyra-assignment", "payout.decline.error")
    }
  end
end
