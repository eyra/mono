defmodule Systems.Budget.FundingPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :funding

  alias CoreWeb.UI.ContentList
  alias Frameworks.Pixel.Line
  alias Frameworks.Pixel.Text.{Title1, Title2, Title3}
  alias Frameworks.Pixel.{Square, SquareContainer}

  alias Systems.{
    Budget,
    Bookkeeping,
    Campaign
  }

  data(create_budget, :map)
  data(edit_button, :map)
  data(deposit_button, :map)
  data(budgets, :list)
  data(selected_budget, :any, default: nil)
  data(campaign_items, :list, default: [])
  data(balance, :any, default: nil)
  data(squares, :list)
  data(popup, :any)

  @impl true
  def mount(_params, %{"locale" => locale} = _session, socket) do
    create_budget = %{
      state: :transparent,
      title: dgettext("eyra-budget", "funding.budgets.new.title"),
      icon: {:static, "add_tertiary"},
      action: %{type: :send, event: "create_budget", item: "first", target: false}
    }

    edit_button = %{
      action: %{type: :send, event: "edit_budget", target: false},
      face: %{type: :label, label: dgettext("eyra-budget", "edit.button.label"), icon: :edit}
    }

    deposit_button = %{
      action: %{type: :send, event: "deposit_money", target: false},
      face: %{
        type: :label,
        label: dgettext("eyra-budget", "deposit.button.label"),
        icon: :deposit
      }
    }

    {
      :ok,
      socket
      |> assign(
        popup: nil,
        locale: locale,
        create_budget: create_budget,
        edit_button: edit_button,
        deposit_button: deposit_button
      )
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> update_campaigns()
    }
  end

  defp update_campaigns(%{assigns: %{selected_budget: nil}} = socket) do
    socket |> assign(campaign_items: [])
  end

  defp update_campaigns(
         %{assigns: %{current_user: user, selected_budget: selected_budget}} = socket
       ) do
    campaign_items =
      selected_budget
      |> Campaign.Public.list_by_budget(Campaign.Model.preload_graph(:full))
      |> Enum.map(&to_content_list_item(&1, user, url_resolver(socket)))

    socket |> assign(campaign_items: campaign_items)
  end

  defp to_content_list_item(campaign, user, url_resolver) do
    ViewModelBuilder.view_model(campaign, {__MODULE__, :budget_campaigns}, user, url_resolver)
  end

  defp update_budgets(%{assigns: %{current_user: user}} = socket) do
    budgets =
      Budget.Public.list_owned(user, [
        :fund,
        :reserve,
        currency: Budget.CurrencyModel.preload_graph(:full)
      ])
      |> Enum.filter(&(&1.currency.type == :legal))

    socket |> assign(budgets: budgets)
  end

  defp update_selected_budget(%{assigns: %{budgets: budgets, selected_budget: nil}} = socket) do
    budget = List.first(budgets)
    socket |> assign(selected_budget: budget)
  end

  defp update_selected_budget(
         %{assigns: %{budgets: budgets, selected_budget: %{id: selected_id}}} = socket
       ) do
    budget = Enum.find(budgets, &(&1.id == selected_id))
    socket |> assign(selected_budget: budget)
  end

  defp update_balance(%{assigns: %{selected_budget: nil}} = socket) do
    socket |> assign(balance: nil)
  end

  defp update_balance(
         %{assigns: %{selected_budget: %{currency: currency} = budget, locale: locale}} = socket
       ) do
    available = Budget.Model.amount_available(budget)
    reserved = Budget.Model.amount_reserved(budget)
    spend = Budget.Model.amount_spend(budget)

    balance = %{
      available: Budget.CurrencyModel.label(currency, locale, available),
      reserved: Budget.CurrencyModel.label(currency, locale, reserved),
      spend: Budget.CurrencyModel.label(currency, locale, spend),
      progress: %{
        size: max(available, reserved + spend),
        bars: [
          %{
            color: :warning,
            size: available + reserved
          },
          %{
            color: :success,
            size: available
          }
        ]
      }
    }

    socket |> assign(balance: balance)
  end

  defp update_squares(
         %{assigns: %{budgets: budgets, selected_budget: selected_budget, locale: locale}} =
           socket
       ) do
    socket |> assign(squares: Enum.map(budgets, &to_square(&1, selected_budget, locale)))
  end

  defp to_square(
         %Budget.Model{id: id, name: name, fund: fund, currency: currency, icon: icon} = _budget,
         %{id: selected_id},
         locale
       ) do
    %{debit: debit, credit: credit} = Bookkeeping.Public.balance(fund)
    subtitle = Budget.CurrencyModel.label(currency, locale, credit - debit)

    state =
      if selected_id == id do
        :active
      else
        :solid
      end

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "select_budget", item: id, target: false},
      state: state
    }
  end

  @impl true
  def handle_event("create_budget", _, %{assigns: %{current_user: user, locale: locale}} = socket) do
    popup = %{
      module: Systems.Budget.Form,
      id: :create_budget,
      budget: nil,
      user: user,
      locale: locale,
      target: self()
    }

    {
      :noreply,
      socket |> show_popup(popup)
    }
  end

  @impl true
  def handle_event(
        "edit_budget",
        _,
        %{assigns: %{selected_budget: budget, current_user: user, locale: locale}} = socket
      ) do
    popup = %{
      module: Systems.Budget.Form,
      id: :create_budget,
      budget: budget,
      user: user,
      locale: locale,
      target: self()
    }

    {
      :noreply,
      socket |> show_popup(popup)
    }
  end

  @impl true
  def handle_event("deposit_money", _, %{assigns: %{selected_budget: budget}} = socket) do
    popup = %{
      module: Systems.Budget.DepositForm,
      budget: budget,
      target: self()
    }

    {
      :noreply,
      socket |> show_popup(popup)
    }
  end

  @impl true
  def handle_event(
        "select_budget",
        %{"item" => budget_id},
        %{assigns: %{budgets: budgets}} = socket
      ) do
    selected_budget = budgets |> Enum.find(&(&1.id == String.to_integer(budget_id)))

    {
      :noreply,
      socket
      |> assign(selected_budget: selected_budget)
      |> update_balance()
      |> update_squares()
      |> update_campaigns()
    }
  end

  @impl true
  def handle_info(%{module: Systems.Budget.DepositForm, action: "saved"}, socket) do
    {
      :noreply,
      socket
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> hide_popup()
    }
  end

  @impl true
  def handle_info(%{module: Systems.Budget.Form, action: "saved"}, socket) do
    {
      :noreply,
      socket
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> hide_popup()
    }
  end

  @impl true
  def handle_info(%{module: _, action: "cancel"}, socket) do
    {
      :noreply,
      socket |> hide_popup()
    }
  end

  defp show_popup(socket, popup) do
    socket |> assign(popup: popup)
  end

  defp hide_popup(socket) do
    socket |> assign(popup: nil)
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("eyra-budget", "funding.title")} menus={@menus}>
      <Popup :if={@popup}>
        <div class="p-8 w-popup-md bg-white shadow-2xl rounded">
          <Dynamic.LiveComponent id={:funding_popup} module={@popup.module} {...@popup} />
        </div>
      </Popup>
      <MarginY id={:page_top} />
      <ContentArea>
        <Title1>{dgettext("eyra-budget", "funding.budgets.title")} <span class="text-primary">{Enum.count(@squares)}</span></Title1>
        <SquareContainer>
          <Square {...@create_budget} />
          <Square :for={square <- @squares} {...square} />
        </SquareContainer>

        <div :if={@selected_budget} class="flex flex-col gap-10">
          <div />
          <Line />
          <div class="flex flex-row gap-8">
            <Title2 margin="">{@selected_budget.name}</Title2>
            <div class="flex-grow" />
            <DynamicButton vm={@edit_button} />
            <DynamicButton vm={@deposit_button} />
          </div>
          <Budget.BalanceView :if={@balance} {...@balance} />
          <Title3 margin="">{dgettext("eyra-budget", "linked.assignments.title")} <span class="text-primary">{Enum.count(@campaign_items)}</span></Title3>
          <ContentList items={@campaign_items} />
        </div>
      </ContentArea>
    </Workspace>
    """
  end
end
