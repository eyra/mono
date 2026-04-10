defmodule Systems.Assignment.BudgetForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.Budget

  @impl true
  def update(
        %{id: id, assignment: assignment, user: user, active_currency: active_currency},
        socket
      ) do
    reward_cents = assignment.info.subject_reward || 0

    changeset =
      {%{subject_count: 0}, %{subject_count: :integer}}
      |> Ecto.Changeset.change()

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        user: user,
        active_currency: active_currency,
        changeset: changeset,
        subject_count: 0,
        reward_cents: reward_cents,
        total_cents: 0
      )
    }
  end

  @impl true
  def handle_event("update_slots", %{"slots" => %{"subject_count" => count_str}}, socket) do
    count = parse_int(count_str)
    total_cents = count * socket.assigns.reward_cents

    {
      :noreply,
      socket
      |> assign(subject_count: count, total_cents: total_cents)
    }
  end

  @impl true
  def handle_event(
        "confirm",
        _,
        %{assigns: %{subject_count: count, assignment: assignment, user: user}} = socket
      )
      when count > 0 do
    case Budget.Public.create_pay_in(assignment, user, count) do
      {:ok, %{payment_url: nil}} ->
        {:noreply, socket |> send_event(:parent, "budget_form_submit")}

      {:ok, %{payment_url: payment_url}} ->
        {:noreply, redirect(socket, external: payment_url)}

      {:error, reason} ->
        require Logger
        Logger.warning("[BudgetForm] Payment creation failed: #{inspect(reason)}")
        {:noreply, socket |> flash_error()}
    end
  end

  @impl true
  def handle_event("confirm", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> send_event(:parent, "budget_form_cancelled")}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2>
        <%= dgettext("eyra-assignment", "budget_form.title") %>
      </Text.title2>
      <Text.body>
        <%= dgettext("eyra-assignment", "budget_form.description") %>
      </Text.body>
      <.spacing value="L" />

      <.form id={"#{@id}_slots"} :let={form} for={@changeset} as={:slots} phx-change="update_slots" phx-target={@myself}>
        <.number_input
          form={form}
          field={:subject_count}
          label_text={dgettext("eyra-assignment", "budget_form.slots.label")}
          debounce="300"
        />
      </.form>

      <.spacing value="M" />

      <div class="mb-2">
        <div class="text-title6 font-title6 text-grey1">
          <%= dgettext("eyra-assignment", "budget_form.total.label") %>
        </div>
      </div>
      <div class="text-bodylarge font-body text-grey1 font-bold">
        <%= format_cents(@total_cents) %>
        <span class="font-normal text-bodysmall text-grey2 ml-2">
          | <%= dgettext("eyra-assignment", "budget_form.breakdown",
            count: @subject_count,
            reward: format_cents(@reward_cents)
          ) %>
        </span>
      </div>

      <.spacing value="L" />

      <div class="flex flex-row gap-4 items-center">
        <Button.dynamic
          action={%{type: :send, event: "confirm", target: @myself}}
          face={%{type: :primary, label: dgettext("eyra-assignment", "budget_form.confirm.button")}}
          enabled?={@subject_count > 0}
        />
        <Button.dynamic
          action={%{type: :send, event: "cancel", target: @myself}}
          face={%{type: :label, label: dgettext("eyra-assignment", "budget_form.cancel.button"), text_color: "text-primary"}}
        />
      </div>
    </div>
    """
  end
end
