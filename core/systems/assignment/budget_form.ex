defmodule Systems.Assignment.BudgetForm do
  use CoreWeb.LiveForm

  require Logger

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.Assignment
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Budget
  alias Systems.Payment

  @impl true
  def update(
        %{
          id: id,
          assignment: %{info: %{subject_reward: subject_reward} = info} = assignment,
          user: user,
          active_currency: active_currency,
          reward_locked?: reward_locked?
        },
        socket
      ) do
    reward_cents = subject_reward || 0

    slots_changeset =
      {%{subject_count: 0}, %{subject_count: :integer}}
      |> Ecto.Changeset.change()

    fee_changeset = Assignment.InfoModel.changeset(info, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        info: info,
        user: user,
        active_currency: active_currency,
        reward_locked?: reward_locked?,
        slots_changeset: slots_changeset,
        fee_changeset: fee_changeset,
        subject_count: 0,
        reward_cents: reward_cents,
        partner_fee_percentage: Payment.Public.partner_fee_percentage()
      )
      |> assign_totals(0, reward_cents)
    }
  end

  @impl true
  def handle_event("update_slots", %{"slots" => %{"subject_count" => count_str}}, socket) do
    count = parse_int(count_str)

    {
      :noreply,
      socket
      |> assign(subject_count: count)
      |> assign_totals(count, socket.assigns.reward_cents)
    }
  end

  @impl true
  def handle_event(
        "save_fee",
        %{"info_model" => attrs},
        %{assigns: %{assignment: assignment, info: info, subject_count: subject_count}} = socket
      ) do
    attrs = convert_subject_reward(attrs)
    changeset = Assignment.InfoModel.changeset(info, :auto_save, attrs)

    case Core.Persister.save(changeset.data, changeset) do
      {:ok, updated_info} ->
        reward_cents = updated_info.subject_reward || 0

        {
          :noreply,
          socket
          |> assign(
            assignment: %{assignment | info: updated_info},
            info: updated_info,
            fee_changeset: Assignment.InfoModel.changeset(updated_info, :create, %{}),
            reward_cents: reward_cents
          )
          |> assign_totals(subject_count, reward_cents)
        }

      {:error, changeset} ->
        {:noreply, assign(socket, fee_changeset: changeset)}
    end
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

  defp assign_totals(socket, subject_count, reward_cents) do
    base_cents = subject_count * reward_cents
    fee_cents = Payment.Public.partner_fee_amount(base_cents)

    assign(socket,
      base_cents: base_cents,
      fee_cents: fee_cents,
      total_cents: base_cents + fee_cents
    )
  end

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} when n >= 0 -> n
      _ -> 0
    end
  end

  defp parse_int(_), do: 0

  defp convert_subject_reward(%{"subject_reward" => value} = attrs) when is_binary(value) do
    Map.put(attrs, "subject_reward", CurrencyHelpers.display_to_cents(value))
  end

  defp convert_subject_reward(attrs), do: attrs

  defp cents_to_display(value), do: CurrencyHelpers.cents_to_display(value)
  defp format_cents(value), do: CurrencyHelpers.format_cents(value)

  defp confirm_enabled?(%{reward_locked?: true, subject_count: count}), do: count > 0

  defp confirm_enabled?(%{subject_count: count, reward_cents: reward_cents}),
    do: count > 0 and reward_cents > 0

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :confirm_enabled?, confirm_enabled?(assigns))

    ~H"""
    <div>
      <Text.title2>
        <%= dgettext("eyra-assignment", "budget_form.title") %>
      </Text.title2>
      <Text.body>
        <%= dgettext("eyra-assignment", "budget_form.description") %>
      </Text.body>
      <.spacing value="L" />

      <%= if not @reward_locked? do %>
        <.form id={"#{@id}_fee"} :let={fee_form} for={@fee_changeset} phx-change="save_fee" phx-target={@myself}>
          <.text_input
            form={fee_form}
            field={:aim_of_study}
            label_text={dgettext("eyra-assignment", "budget_form.aim.label")}
            maxlength="250"
            testid="budget-form-aim-input"
          />
          <div class="-mt-3 mb-4 text-label font-label text-grey2">
            <%= dgettext("eyra-assignment", "budget_form.aim.hint") %>
          </div>
          <.currency_input
            form={fee_form}
            field={:subject_reward}
            label_text={dgettext("eyra-assignment", "budget_form.fee.label")}
            value={cents_to_display(input_value(fee_form, :subject_reward))}
            active_currency={@active_currency}
            currencies={[@active_currency]}
            testid="budget-form-reward-input"
          />
          <div class="-mt-3 mb-4 text-label font-label text-grey2">
            <%= dgettext("eyra-assignment", "budget_form.fee.hint") %>
          </div>
        </.form>
      <% end %>

      <.form id={"#{@id}_slots"} :let={form} for={@slots_changeset} as={:slots} phx-change="update_slots" phx-target={@myself}>
        <.number_input
          form={form}
          field={:subject_count}
          label_text={dgettext("eyra-assignment", "budget_form.slots.label")}
          debounce="300"
          testid="budget-form-slots-input"
        />
      </.form>

      <.spacing value="M" />

      <div class="mb-3">
        <div class="text-title6 font-title6 text-grey1">
          <%= dgettext("eyra-assignment", "budget_form.costs.label") %>
        </div>
      </div>
      <div class="flex flex-col gap-1">
        <div class="flex flex-row justify-between text-bodymedium font-body text-grey2">
          <div>
            <%= dgettext("eyra-assignment", "budget_form.subtotal.label",
              count: display_count(@subject_count),
              reward: format_cents(@reward_cents)
            ) %>
          </div>
          <div><%= format_cents(@base_cents) %></div>
        </div>
        <%= if @fee_cents > 0 do %>
          <div class="flex flex-row justify-between text-bodymedium font-body text-grey2">
            <div>
              <%= dgettext("eyra-assignment", "budget_form.partner_fee.label") %>
            </div>
            <div><%= format_cents(@fee_cents) %></div>
          </div>
        <% end %>
        <div class="border-t border-grey4 my-2"></div>
        <div class="flex flex-row justify-between text-bodylarge font-body text-grey1 font-bold">
          <div><%= dgettext("eyra-assignment", "budget_form.total.label") %></div>
          <div><%= format_cents(@total_cents) %></div>
        </div>
      </div>

      <.spacing value="L" />

      <div class="flex flex-row gap-4 items-center">
        <Button.dynamic
          action={%{type: :send, event: "confirm", target: @myself}}
          face={%{type: :primary, label: dgettext("eyra-assignment", "budget_form.confirm.button")}}
          enabled?={@confirm_enabled?}
          testid="budget-form-confirm-button"
        />
        <Button.dynamic
          action={%{type: :send, event: "cancel", target: @myself}}
          face={%{type: :label, label: dgettext("eyra-assignment", "budget_form.cancel.button"), text_color: "text-primary"}}
          testid="budget-form-cancel-button"
        />
      </div>
    </div>
    """
  end

  defp display_count(0), do: "-"
  defp display_count(n), do: n
end
