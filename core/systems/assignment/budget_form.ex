defmodule Systems.Assignment.BudgetForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  @impl true
  def update(
        %{id: id, assignment: assignment, active_currency: active_currency},
        socket
      ) do
    reward_cents = assignment.info.subject_reward || 0

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        active_currency: active_currency,
        subject_count: 0,
        reward_cents: reward_cents,
        total_cents: 0
      )
    }
  end

  @impl true
  def handle_event("update_slots", %{"subject_count" => count_str}, socket) do
    count = parse_int(count_str)
    reward_cents = socket.assigns.reward_cents
    total_cents = count * reward_cents

    {
      :noreply,
      socket
      |> assign(subject_count: count, total_cents: total_cents)
    }
  end

  @impl true
  def handle_event("confirm", _, %{assigns: %{subject_count: count}} = socket) when count > 0 do
    send(self(), {:handle_auto_save_done, socket.assigns.id})

    {
      :noreply,
      socket
    }
  end

  @impl true
  def handle_event("confirm", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    send(self(), {:handle_auto_save_done, socket.assigns.id})
    {:noreply, socket}
  end

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} when n >= 0 -> n
      _ -> 0
    end
  end

  defp parse_int(_), do: 0

  defp format_cents(cents) when is_integer(cents) and cents > 0 do
    euros = div(cents, 100)
    remaining = rem(cents, 100)
    "€#{euros},#{String.pad_leading("#{remaining}", 2, "0")}"
  end

  defp format_cents(_), do: "€0,00"

  defp currency_symbol(:EUR), do: "€"
  defp currency_symbol(:USD), do: "$"
  defp currency_symbol(c), do: to_string(c)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 w-popup-md">
      <Text.title3>
        <%= dgettext("eyra-assignment", "budget_form.title") %>
      </Text.title3>
      <.spacing value="M" />

      <div class="mb-6">
        <div class="text-title6 font-title6 text-grey1 mb-2">
          <%= dgettext("eyra-assignment", "budget_form.reward.label") %>
        </div>
        <div class="text-bodylarge font-body text-grey1">
          <%= currency_symbol(@active_currency) %> <%= format_cents(@reward_cents) %>
        </div>
      </div>

      <form phx-change="update_slots" phx-target={@myself}>
        <.number_input
          form={%{}}
          field={:subject_count}
          label_text={dgettext("eyra-assignment", "budget_form.slots.label")}
          debounce="300"
        />
      </form>

      <.spacing value="M" />

      <div class="bg-grey6 rounded-md p-4 mb-6">
        <div class="flex justify-between items-center">
          <div class="text-bodymedium font-body text-grey2">
            <%= dgettext("eyra-assignment", "budget_form.total.label") %>
          </div>
          <div class="text-title4 font-title4 text-grey1">
            <%= format_cents(@total_cents) %>
          </div>
        </div>
        <div class="text-bodysmall font-body text-grey3 mt-1">
          <%= dgettext("eyra-assignment", "budget_form.breakdown",
            count: @subject_count,
            reward: format_cents(@reward_cents)
          ) %>
        </div>
      </div>

      <div class="flex flex-row gap-4">
        <Button.dynamic
          action={%{type: :send, event: "confirm", target: @myself}}
          face={%{type: :primary, label: dgettext("eyra-assignment", "budget_form.confirm.button")}}
          enabled?={@subject_count > 0}
        />
        <Button.dynamic
          action={%{type: :send, event: "cancel", target: @myself}}
          face={%{type: :label, label: dgettext("eyra-assignment", "budget_form.cancel.button"), text_color: "text-grey1"}}
        />
      </div>
    </div>
    """
  end
end
