defmodule Systems.Fund.PayInRequestForm do
  @moduledoc false
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Fund
  alias Systems.Payment

  require Logger

  @impl true
  def update(
        %{
          id: id,
          assignment:
            %{info: %{subject_reward: subject_reward, aim_of_study: aim_of_study}} = assignment,
          user: user,
          active_currency: active_currency,
          reward_locked?: reward_locked?
        },
        socket
      ) do
    reward_cents = subject_reward || 0

    request = %Fund.PayInRequestModel{
      subject_count: 0,
      subject_reward: reward_cents,
      aim_of_study: aim_of_study
    }

    changeset = Fund.PayInRequestModel.changeset(request)

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        user: user,
        active_currency: active_currency,
        reward_locked?: reward_locked?,
        request: request,
        changeset: changeset,
        validate?: false,
        reward_input: CurrencyHelpers.cents_to_display(reward_cents),
        partner_fee_percentage: Payment.Public.partner_fee_percentage()
      )
      |> assign_totals()
    }
  end

  @impl true
  def handle_event("update", %{"pay_in_request" => attrs}, %{assigns: assigns} = socket) do
    changeset = build_changeset(assigns.request, attrs, assigns.validate?)

    {:noreply,
     socket
     |> assign(changeset: changeset, reward_input: attrs["subject_reward"] || "")
     |> assign_totals()}
  end

  @impl true
  def handle_event("confirm", %{"pay_in_request" => attrs}, socket) do
    case Fund.Public.create_pay_in(socket.assigns.assignment, socket.assigns.user, attrs) do
      {:ok, %{payment_url: nil}} ->
        {:noreply, send_event(socket, :parent, "pay_in_request_form_submit")}

      {:ok, %{payment_url: payment_url}} ->
        {:noreply, redirect(socket, external: payment_url)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, validate?: true)}

      {:error, reason} ->
        Logger.warning("[PayInRequestForm] Payment creation failed: #{inspect(reason)}")
        {:noreply, flash_error(socket)}
    end
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, send_event(socket, :parent, "pay_in_request_form_cancelled")}
  end

  defp build_changeset(request, attrs, false) do
    Fund.PayInRequestModel.changeset(request, attrs)
  end

  defp build_changeset(request, attrs, true) do
    request
    |> Fund.PayInRequestModel.changeset(attrs)
    |> Fund.PayInRequestModel.validate()
    |> Map.put(:action, :validate)
  end

  defp assign_totals(%{assigns: %{changeset: changeset}} = socket) do
    subject_count = Ecto.Changeset.get_field(changeset, :subject_count) || 0
    reward_cents = Ecto.Changeset.get_field(changeset, :subject_reward) || 0
    base_cents = subject_count * reward_cents
    fee_cents = Payment.Public.partner_fee_amount(base_cents)

    assign(socket,
      base_cents: base_cents,
      fee_cents: fee_cents,
      total_cents: base_cents + fee_cents,
      subject_count: subject_count,
      reward_cents: reward_cents
    )
  end

  defp format_cents(value), do: CurrencyHelpers.format_cents(value)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_content"} phx-hook="LiveContent" data-show-errors={true}>
      <Text.title3>
        <%= dgettext("eyra-assignment", "pay_in_request_form.title") %>
      </Text.title3>
      <Text.body>
        <%= dgettext("eyra-assignment", "pay_in_request_form.description") %>
      </Text.body>
      <.spacing value="M" />

      <.form
        id={"#{@id}_form"}
        :let={form}
        for={@changeset}
        as={:pay_in_request}
        phx-change="update"
        phx-submit="confirm"
        phx-target={@myself}
      >
        <%= if not @reward_locked? do %>
          <.text_input
            form={form}
            field={:aim_of_study}
            label_text={dgettext("eyra-assignment", "pay_in_request_form.aim.label")}
            placeholder={dgettext("eyra-assignment", "pay_in_request_form.aim.placeholder")}
            maxlength="250"
            reserve_error_space={false}
            testid="pay-in-request-form-aim-input"
          />
          <.spacing value="S" />
          <.currency_input
            form={form}
            field={:subject_reward}
            label_text={dgettext("eyra-assignment", "pay_in_request_form.fee.label")}
            value={@reward_input}
            active_currency={@active_currency}
            currencies={[@active_currency]}
            reserve_error_space={false}
            testid="pay-in-request-form-reward-input"
          />
          <.spacing value="S" />
        <% end %>

        <.number_input
          form={form}
          field={:subject_count}
          label_text={dgettext("eyra-assignment", "pay_in_request_form.slots.label")}
          debounce="300"
          reserve_error_space={false}
          testid="pay-in-request-form-slots-input"
        />

        <.spacing value="M" />

        <div class="mb-3">
          <div class="text-title6 font-title6 text-grey1">
            <%= dgettext("eyra-assignment", "pay_in_request_form.costs.label") %>
          </div>
        </div>
        <div class="flex flex-col gap-1">
          <div class="flex flex-row justify-between text-bodymedium font-body text-grey1">
            <div>
              <%= dgettext("eyra-assignment", "pay_in_request_form.subtotal.label",
                count: display_count(@subject_count),
                reward: format_cents(@reward_cents)
              ) %>
            </div>
            <div><%= format_cents(@base_cents) %></div>
          </div>
          <div class="flex flex-row justify-between text-bodymedium font-body text-grey1">
            <div>
              <%= dgettext("eyra-assignment", "pay_in_request_form.partner_fee.label",
                percentage: @partner_fee_percentage
              ) %>
            </div>
            <div><%= format_cents(@fee_cents) %></div>
          </div>
          <div class="border-t border-grey4 my-2"></div>
          <div class="flex flex-row justify-between text-title6 font-title6 text-grey1">
            <div><%= dgettext("eyra-assignment", "pay_in_request_form.total.label") %></div>
            <div><%= format_cents(@total_cents) %></div>
          </div>
        </div>

        <.spacing value="L" />

        <div class="flex flex-row gap-4 items-center">
          <Button.dynamic
            action={%{type: :submit}}
            face={%{type: :primary, label: dgettext("eyra-assignment", "pay_in_request_form.confirm.button")}}
            testid="pay-in-request-form-confirm-button"
          />
          <Button.dynamic
            action={%{type: :send, event: "cancel", target: @myself}}
            face={%{type: :label, label: dgettext("eyra-assignment", "pay_in_request_form.cancel.button"), text_color: "text-primary"}}
            testid="pay-in-request-form-cancel-button"
          />
        </div>
      </.form>
    </div>
    """
  end

  defp display_count(0), do: "-"
  defp display_count(n), do: n
end
