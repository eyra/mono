defmodule Systems.Advert.FundingView do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Square

  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Pool
  alias Systems.Assignment

  @minimal_reward_per_minute 10

  # Handle update from parent
  @impl true
  def update(
        %{assignment: assignment, submission: submission, budget: budget},
        %{assigns: %{id: _id}} = socket
      ) do
    {
      :ok,
      socket
      |> assign(
        assignment: assignment,
        submission: submission,
        budget: budget
      )
      |> update_state()
      |> update_shortage()
      |> update_reward_description()
      |> update_fund_description()
      |> update_budgets()
      |> update_budget_items()
    }
  end

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          assignment: %{budget: budget} = assignment,
          submission: submission,
          user: user
        },
        socket
      ) do
    changeset = Pool.SubmissionModel.changeset(submission, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        submission: submission,
        assignment: assignment,
        changeset: changeset,
        selected_budget: budget,
        user: user,
        locale: CoreWeb.Live.Hook.Locale.get_locale()
      )
      |> update_state()
      |> update_reward()
      |> update_shortage()
      |> update_reward_description()
      |> update_fund_description()
      |> update_budgets()
      |> update_budget_items()
    }
  end

  defp update_state(
         %{
           assigns: %{
             selected_budget: selected_budget,
             assignment: assignment,
             submission: %{reward_value: reward_value}
           }
         } = socket
       ) do
    reward_value = guard_number_nil(reward_value)
    amount_available = Budget.Model.amount_available(selected_budget)

    count =
      if amount_available > 0 and reward_value > 0 do
        floor(amount_available / reward_value)
      else
        0
      end

    open_spot_count = Assignment.Public.open_spot_count(assignment)

    state =
      if count >= open_spot_count do
        :success
      else
        if count > 0 do
          :warning
        else
          :error
        end
      end

    socket |> assign(state: state, count: count, open_spot_count: open_spot_count)
  end

  defp update_reward(
         %{
           assigns: %{
             submission: %{reward_value: reward_value, pool: %{currency: currency}},
             locale: locale
           }
         } = socket
       ) do
    reward_value = guard_number_nil(reward_value)
    reward_value_label = Budget.CurrencyModel.label(currency, locale, reward_value)
    reward_label = dgettext("eyra-advert", "funding.reward.label", amount: reward_value_label)
    socket |> assign(reward_label: reward_label)
  end

  defp update_shortage(
         %{
           assigns: %{
             submission: %{reward_value: reward_value, pool: %{currency: currency}},
             open_spot_count: open_spot_count,
             locale: locale
           }
         } = socket
       ) do
    reward_value = guard_number_nil(reward_value)
    shortage = open_spot_count * reward_value
    shortage_label = Budget.CurrencyModel.label(currency, locale, shortage)
    socket |> assign(shortage_label: shortage_label)
  end

  defp update_reward_description(
         %{
           assigns: %{
             submission: %{pool: %{currency: currency}},
             assignment: %{assignable_inquiry: %{duration: duration}},
             locale: locale
           }
         } = socket
       ) do
    duration = guard_number_nil(duration)
    minimal_reward = @minimal_reward_per_minute * duration
    minimal_reward_label = Budget.CurrencyModel.label(currency, locale, minimal_reward)

    reward_description =
      dgettext("eyra-advert", "funding.reward.description",
        amount: minimal_reward_label,
        duration: duration
      )

    socket |> assign(reward_description: reward_description)
  end

  defp update_fund_description(%{assigns: %{state: state, count: count}} = socket) do
    fund_description =
      case state do
        :success ->
          dgettext("eyra-advert", "funding.fund.description.success")

        :warning ->
          dgettext("eyra-advert", "funding.fund.description.warning", count: count)

        :error ->
          dgettext("eyra-advert", "funding.fund.description.error")
      end

    socket |> assign(fund_description: fund_description)
  end

  defp update_budgets(
         %{assigns: %{submission: %{pool: %{currency: %{id: _id} = currency}}, user: user}} =
           socket
       ) do
    budgets =
      Budget.Public.list_owned_by_currency(user, currency, Budget.Model.preload_graph(:full))

    socket |> assign(budgets: budgets)
  end

  defp update_budget_items(
         %{
           assigns: %{
             budgets: budgets,
             selected_budget: selected_budget,
             state: state,
             locale: locale,
             myself: myself
           }
         } = socket
       ) do
    socket
    |> assign(
      budget_items: Enum.map(budgets, &to_item(&1, selected_budget, state, locale, myself))
    )
  end

  defp to_item(
         %Budget.Model{id: id, name: name, fund: fund, currency: currency, icon: icon},
         %{id: selected_id},
         state,
         locale,
         target
       ) do
    %{debit: debit, credit: credit} = Bookkeeping.Public.balance(fund)
    subtitle = Budget.CurrencyModel.label(currency, locale, credit - debit)

    selection_state =
      if selected_id == id do
        {:active, state}
      else
        :solid
      end

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "select_budget", item: id, target: target},
      state: selection_state
    }
  end

  @impl true
  def handle_event(
        "select_budget",
        %{"item" => budget_id},
        %{assigns: %{assignment: assignment, budgets: budgets, changeset: submission_changeset}} =
          socket
      ) do
    selected_budget = budgets |> Enum.find(&(&1.id == String.to_integer(budget_id)))
    changeset = Assignment.Model.changeset(assignment, selected_budget)

    {
      :noreply,
      socket
      |> save(changeset)
      |> copy_entity(:assignment)
      |> assign(selected_budget: selected_budget, changeset: submission_changeset)
      |> update_state()
      |> update_shortage()
      |> update_budgets()
      |> update_budget_items()
      |> update_fund_description()
    }
  end

  @impl true
  def handle_event(
        "change_reward",
        %{"submission_model" => attrs},
        %{assigns: %{submission: submission}} = socket
      ) do
    changeset = Pool.SubmissionModel.changeset(submission, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
      |> copy_entity(:submission)
      |> update_state()
      |> update_reward()
      |> update_shortage()
      |> update_budgets()
      |> update_budget_items()
      |> update_fund_description()
    }
  end

  defp copy_entity(%{assigns: %{entity: entity}} = socket, field) do
    socket |> assign(field, entity)
  end

  defp guard_number_nil(nil), do: 0
  defp guard_number_nil(number) when is_number(number), do: number
  defp guard_number_nil(number) when is_binary(number), do: String.to_integer(number)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-advert", "funding.title") %></Text.title2>
        <Text.body><%= dgettext("eyra-advert", "funding.description", amount: @shortage_label, count: @open_spot_count) %></Text.body>
        <.spacing value="M" />

        <Text.title4><%= dgettext("eyra-advert", "funding.fund.title") %></Text.title4>
        <.spacing value="XS" />
        <Text.body><%= @fund_description %></Text.body>
        <.spacing value="XS" />
        <Square.container>
          <%= for budget_item <- @budget_items do %>
            <Square.item {budget_item} />
          <% end %>
        </Square.container>
        <.spacing value="L" />

        <.form id="main_form" :let={form} for={@changeset} phx-change="change_reward" phx-target={@myself} >
          <Text.title4><%= dgettext("eyra-advert", "funding.reward.title") %></Text.title4>
          <.spacing value="XS" />
          <Text.body><%= @reward_description %></Text.body>
          <.spacing value="XS" />
          <div class="w-form">
            <.number_input form={form} field={:reward_value} label_text={@reward_label} />
          </div>
        </.form>
      </Area.content>
    </div>
    """
  end
end
