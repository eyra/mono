defmodule Systems.Assignment.PaymentView do
  use CoreWeb, :live_component

  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Button

  alias Systems.Assignment
  alias Systems.Budget

  @impl true
  def update(
        %{
          id: id,
          assignment: assignment,
          title: title,
          viewport: viewport,
          breakpoint: breakpoint,
          content_flags: content_flags
        },
        socket
      ) do
    info = assignment.info
    changeset = Assignment.InfoModel.changeset(info, :create, %{})
    transactions = list_transactions(assignment)
    pending_payouts = count_pending_payouts(assignment)
    active_currency = get_active_currency(assignment)

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        entity: info,
        changeset: changeset,
        title: title,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags,
        transactions: transactions,
        pending_payouts: pending_payouts,
        active_currency: active_currency
      )
    }
  end

  @impl true
  def compose(:budget_form, %{assignment: assignment, active_currency: active_currency}) do
    %{
      module: Assignment.BudgetForm,
      params: %{
        assignment: assignment,
        active_currency: active_currency
      }
    }
  end

  @impl true
  def handle_event("add_budget", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:budget_form)
      |> show_modal(:budget_form, :compact)
    }
  end

  @impl true
  def handle_event("budget_form_hide", _, socket) do
    {:noreply, socket |> hide_modal(:budget_form)}
  end

  @impl true
  def handle_event("budget_form_submit", _, %{assigns: %{assignment: assignment}} = socket) do
    {
      :noreply,
      socket
      |> assign(transactions: list_transactions(assignment))
      |> hide_modal(:budget_form)
    }
  end

  @impl true
  def handle_event("save", %{"info_model" => attrs} = params, %{assigns: %{entity: entity}} = socket) do
    attrs = convert_subject_reward(attrs)
    changeset = Assignment.InfoModel.changeset(entity, :auto_save, attrs)

    {
      :noreply,
      socket
      |> maybe_update_currency(params)
      |> save(changeset)
    }
  end

  @impl true
  def handle_event("save", %{"currency" => _} = params, socket) do
    {:noreply, maybe_update_currency(socket, params)}
  end

  defp maybe_update_currency(socket, %{"currency" => currency_string}) do
    currency = String.to_existing_atom(currency_string)

    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      %Budget.CurrencyLedgerModel{} = ledger ->
        update_fund_currency_ledger(socket, ledger)

      nil ->
        socket
    end
  end

  defp maybe_update_currency(socket, _), do: socket

  defp save(socket, changeset) do
    case Core.Persister.save(changeset.data, changeset) do
      {:ok, entity} ->
        assign(socket, entity: entity, changeset: Assignment.InfoModel.changeset(entity, :create, %{}))

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  defp update_fund_currency_ledger(
         %{assigns: %{assignment: %{fund: fund}}} = socket,
         %Budget.CurrencyLedgerModel{} = ledger
       )
       when not is_nil(fund) do
    fund
    |> Ecto.Changeset.change(%{currency_ledger_id: ledger.id})
    |> Core.Repo.update!()

    assign(socket, active_currency: ledger.currency)
  end

  defp update_fund_currency_ledger(socket, %Budget.CurrencyLedgerModel{currency: currency}) do
    assign(socket, active_currency: currency)
  end

  defp get_active_currency(%{fund: %{currency_ledger: %{currency: currency}}}), do: currency
  defp get_active_currency(_), do: :EUR

  defp list_transactions(%{id: _assignment_id}) do
    Budget.TransactionModel
    |> Core.Repo.all()
    |> Enum.filter(&(&1.target_fund_id != nil))
  end

  defp count_pending_payouts(_assignment), do: 0

  defp convert_subject_reward(%{"subject_reward" => value} = attrs) when is_binary(value) do
    Map.put(attrs, "subject_reward", display_to_cents(value))
  end

  defp convert_subject_reward(attrs), do: attrs

  defp display_to_cents(value) do
    case Decimal.parse(value) do
      {decimal, _} ->
        decimal
        |> Decimal.mult(100)
        |> Decimal.round(0)
        |> Decimal.to_integer()

      :error ->
        0
    end
  end

  defp cents_to_display(nil), do: ""
  defp cents_to_display(0), do: ""

  defp cents_to_display(cents) when is_integer(cents) do
    euros = div(cents, 100)
    remaining = rem(cents, 100)
    "#{euros}.#{String.pad_leading("#{remaining}", 2, "0")}"
  end

  defp cents_to_display(value) when is_binary(value) do
    case Integer.parse(value) do
      {cents, _} -> cents_to_display(cents)
      :error -> ""
    end
  end

  defp format_cents(cents) when is_integer(cents) and cents > 0 do
    euros = div(cents, 100)
    remaining = rem(cents, 100)
    "€#{euros},#{String.pad_leading("#{remaining}", 2, "0")}"
  end

  defp format_cents(_), do: "€0,00"

  defp budget_description(subject_count, subject_reward) do
    reward_label = format_cents(subject_reward)

    dgettext("eyra-assignment", "payment.budget.description",
      count: subject_count || 0,
      reward: reward_label
    )
  end

  defp status_tag(:completed) do
    %{
      text: dgettext("eyra-assignment", "payment.status.paid"),
      bg_color: "bg-success",
      text_color: "text-success"
    }
  end

  defp status_tag(:pending) do
    %{
      text: dgettext("eyra-assignment", "payment.status.pending"),
      bg_color: "bg-warning",
      text_color: "text-warning"
    }
  end

  defp status_tag(_) do
    %{
      text: dgettext("eyra-assignment", "payment.status.draft"),
      bg_color: "bg-grey3",
      text_color: "text-grey1"
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @title %></Text.title2>
        <.spacing value="L" />

        <%= if @pending_payouts > 0 do %>
          <div class="bg-warning bg-opacity-20 rounded-md p-6 mb-8 flex items-center justify-between">
            <div>
              <div class="text-title6 font-title6 text-grey1">
                <%= dgettext("eyra-assignment", "payment.payout.title") %>
              </div>
              <div class="text-bodysmall font-body text-grey2">
                <%= dgettext("eyra-assignment", "payment.payout.description") %>
              </div>
            </div>
            <Button.dynamic
              action={%{type: :send, event: "check_payouts", target: @myself}}
              face={%{type: :secondary, label: dgettext("eyra-assignment", "payment.payout.button", count: @pending_payouts), border_color: "border-grey1", text_color: "text-grey1"}}
            />
          </div>
        <% end %>

        <div class="mb-6">
          <.form id={"#{@id}_reward"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
            <.currency_input
              form={form}
              field={:subject_reward}
              value={cents_to_display(input_value(form, :subject_reward))}
              active_currency={@active_currency}
              label_text={dgettext("eyra-assignment", "payment.reward.label")}
              disabled={@transactions != []}
            />
          </.form>
        </div>

        <Text.title3>
          <%= dgettext("eyra-assignment", "payment.budgets.title") %>
        </Text.title3>

        <div class="flex flex-col gap-4 mb-6">
          <%= for {transaction, index} <- Enum.with_index(@transactions, 1) do %>
            <.budget_card transaction={transaction} index={index} />
          <% end %>

          <%= if Enum.empty?(@transactions) do %>
            <div class="text-bodymedium font-body text-grey2 mb-4">
              <%= dgettext("eyra-assignment", "payment.budgets.empty") %>
            </div>
          <% end %>
        </div>

        <Button.dynamic
          action={%{type: :send, event: "add_budget", target: @myself}}
          face={%{type: :primary, label: dgettext("eyra-assignment", "payment.add_budget.button")}}
        />
      </Area.content>
    </div>
    """
  end

  defp budget_card(assigns) do
    tag = status_tag(assigns.transaction.status)
    assigns = assign(assigns, :tag, tag)

    ~H"""
    <Panel.flat>
      <div class="flex items-start justify-between">
        <div>
          <div class="text-title5 font-title5 text-grey1 mb-1">
            <%= dgettext("eyra-assignment", "payment.budget.title", number: @index) %>
          </div>
          <div class="text-bodysmall font-body text-grey2">
            <%= format_cents(0) %> | <%= budget_description(0, 0) %>
          </div>
        </div>
        <Tag.tag text={@tag.text} bg_color={@tag.bg_color} text_color={@tag.text_color} />
      </div>
    </Panel.flat>
    """
  end
end
