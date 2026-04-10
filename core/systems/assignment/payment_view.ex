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
          user: user,
          title: title,
          viewport: viewport,
          breakpoint: breakpoint,
          content_flags: content_flags
        },
        %{assigns: %{myself: myself}} = socket
      ) do
    info = assignment.info
    changeset = Assignment.InfoModel.changeset(info, :create, %{})
    transactions = list_transactions(assignment)
    pending_payouts = count_pending_payouts(assignment)
    active_currency = get_active_currency(assignment)

    add_budget_button = %{
      action: %{type: :send, event: "add_budget", target: myself},
      face: %{type: :primary, label: dgettext("eyra-assignment", "payment.add_budget.button")}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        user: user,
        entity: info,
        changeset: changeset,
        title: title,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags,
        transactions: transactions,
        pending_payouts: pending_payouts,
        active_currency: active_currency,
        add_budget_button: add_budget_button
      )
    }
  end

  @impl true
  def compose(:budget_form, %{
        assignment: assignment,
        user: user,
        active_currency: active_currency
      }) do
    %{
      module: Assignment.BudgetForm,
      params: %{
        assignment: assignment,
        user: user,
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
  def handle_event("budget_form_cancelled", _, socket) do
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
  def handle_event("save", %{"info_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    attrs = convert_subject_reward(attrs)
    changeset = Assignment.InfoModel.changeset(entity, :auto_save, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
    }
  end

  defp save(socket, changeset) do
    case Core.Persister.save(changeset.data, changeset) do
      {:ok, entity} ->
        assign(socket,
          entity: entity,
          changeset: Assignment.InfoModel.changeset(entity, :create, %{})
        )

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  defp get_active_currency(%{fund: %{currency_ledger: %{currency: currency}}}), do: currency
  defp get_active_currency(_), do: :EUR

  defp list_transactions(%{fund: nil}), do: []

  defp list_transactions(%{fund: fund}) do
    Budget.Public.list_transactions_by_fund(fund)
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

        <div class="mb-8">
          <%= if @transactions != [] do %>
            <.reward_display reward_cents={@entity.subject_reward} active_currency={@active_currency} />
          <% else %>
            <Text.title6>
              <%= dgettext("eyra-assignment", "payment.reward.label") %>
            </Text.title6>
            <div class="text-bodysmall font-body text-grey2 mb-3">
              <%= dgettext("eyra-assignment", "payment.reward.warning") %>
            </div>
            <.form id={"#{@id}_reward"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
              <.currency_input
                form={form}
                field={:subject_reward}
                value={cents_to_display(input_value(form, :subject_reward))}
                active_currency={@active_currency}
                currencies={[@active_currency]}
              />
            </.form>
          <% end %>
        </div>

        <Text.title6>
          <%= dgettext("eyra-assignment", "payment.transactions.title") %>
        </Text.title6>

        <div class="flex flex-col gap-4 mb-6">
          <%= for {transaction, index} <- Enum.with_index(@transactions, 1) do %>
            <.budget_card transaction={transaction} entity={@entity} index={index} />
          <% end %>

          <%= if Enum.empty?(@transactions) do %>
            <div class="text-bodymedium font-body text-grey2 mb-4">
              <%= dgettext("eyra-assignment", "payment.transactions.empty") %>
            </div>
          <% end %>
        </div>

        <Button.dynamic {@add_budget_button} />
      </Area.content>
    </div>
    """
  end

  defp reward_display(assigns) do
    ~H"""
    <Text.title6>
      <%= dgettext("eyra-assignment", "payment.reward.label") %>
    </Text.title6>
    <div class="text-bodysmall font-body text-grey2 mb-3">
      <%= dgettext("eyra-assignment", "payment.reward.locked") %>
    </div>
    <div class="text-title3 font-light text-grey1">
      <%= if (@reward_cents || 0) > 0 do %>
        <%= format_cents(@reward_cents) %> <%= currency_label(@active_currency) %>
      <% else %>
        <%= dgettext("eyra-assignment", "payment.reward.none") %>
      <% end %>
    </div>
    """
  end

  defp currency_label(:EUR), do: "EUR"
  defp currency_label(:USD), do: "USD"
  defp currency_label(c), do: to_string(c)

  defp budget_card(%{transaction: transaction, entity: entity} = assigns) do
    tag = status_tag(transaction.status)
    reward = entity.subject_reward || 0
    total = transaction.subject_count * reward
    assigns = assign(assigns, tag: tag, total: total, reward: reward)

    ~H"""
    <Panel.flat>
      <div class="flex items-start justify-between">
        <div>
          <div class="text-title5 font-title5 text-grey1 mb-1">
            <%= @transaction.invoice_id %>
          </div>
          <div class="text-bodysmall font-body text-grey2">
            <%= format_cents(@total) %> | <%= budget_description(@transaction.subject_count, @reward) %>
          </div>
        </div>
        <Tag.tag text={@tag.text} bg_color={@tag.bg_color} text_color={@tag.text_color} />
      </div>
    </Panel.flat>
    """
  end
end
