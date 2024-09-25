defmodule Systems.Budget.FundingPage do
  use Systems.Content.Composer, :live_workspace

  import Frameworks.Pixel.Content
  import Frameworks.Pixel.Line

  import Systems.Budget.BalanceView

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Square

  alias Systems.Budget
  alias Systems.Bookkeeping
  alias Systems.Advert

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(selected_budget: nil)
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> update_adverts()
    }
  end

  @impl true
  def compose(:create_budget_form, %{user: user, locale: locale}) do
    %{
      module: Systems.Budget.Form,
      params: %{
        budget: nil,
        user: user,
        locale: locale
      }
    }
  end

  @impl true
  def compose(:edit_budget_form, %{selected_budget: selected_budget, user: user, locale: locale}) do
    %{
      module: Systems.Budget.Form,
      params: %{
        budget: selected_budget,
        user: user,
        locale: locale
      }
    }
  end

  @impl true
  def compose(:budget_deposit_form, %{selected_budget: selected_budget}) do
    %{
      module: Systems.Budget.DepositForm,
      params: %{budget: selected_budget}
    }
  end

  defp update_adverts(%{assigns: %{selected_budget: nil}} = socket) do
    socket |> assign(advert_items: [])
  end

  defp update_adverts(%{assigns: %{selected_budget: selected_budget} = assigns} = socket) do
    advert_items =
      selected_budget
      |> Advert.Public.list_by_budget(Advert.Model.preload_graph(:down))
      |> Enum.map(&to_content_list_item(&1, assigns))

    socket |> assign(advert_items: advert_items)
  end

  defp to_content_list_item(advert, assigns) do
    ViewModelBuilder.view_model(advert, {__MODULE__, :budget_adverts}, assigns)
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

  # Events

  @impl true
  def handle_event("create_budget", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:create_budget_form)
      |> show_popup(:create_budget_form)
    }
  end

  @impl true
  def handle_event("edit_budget", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:edit_budget_form)
      |> show_popup(:edit_budget_form)
    }
  end

  @impl true
  def handle_event("deposit_money", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:budget_deposit_form)
      |> show_popup(:budget_deposit_form)
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
      |> update_adverts()
    }
  end

  @impl true
  def handle_event("deposit_saved", %{source: %{name: popup}}, socket) do
    {
      :noreply,
      socket
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> hide_popup(popup)
    }
  end

  @impl true
  def handle_event("budget_saved", %{source: %{name: popup, module: Systems.Budget.Form}}, socket) do
    {
      :noreply,
      socket
      |> update_budgets()
      |> update_selected_budget()
      |> update_balance()
      |> update_squares()
      |> hide_popup(popup)
    }
  end

  @impl true
  def handle_event("budget_cancelled", %{source: %{name: popup}}, socket) do
    {
      :noreply,
      socket
      |> hide_popup(popup)
    }
  end

  @impl true
  def handle_event("deposit_cancelled", %{source: %{name: popup}}, socket) do
    {:noreply, socket |> hide_popup(popup)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-budget", "funding.title")} menus={@menus}>
      <%= if @popup do %>
        <.popup>
          <div class="p-8 w-popup-md bg-white shadow-floating rounded">
            <.live_component id={:funding_popup} module={@popup.module} {@popup} />
          </div>
        </.popup>
      <% end %>
      <Margin.y id={:page_top} />
      <Area.content>
        <Text.title1>
          <%= dgettext("eyra-budget", "funding.budgets.title") %>
          <span class="text-primary"><%= Enum.count(@squares) %></span>
        </Text.title1>
        <Square.container>
          <Square.item {@vm.create_budget} />
          <%= for square <- @squares do %>
            <Square.item {square} />
          <% end %>
        </Square.container>
        <%= if @selected_budget do %>
          <div class="flex flex-col gap-10">
            <div />
            <.line />
            <div class="flex flex-row gap-8">
              <Text.title2 margin=""><%= @selected_budget.name %></Text.title2>
              <div class="flex-grow" />
              <Button.dynamic {@vm.edit_button} />
              <Button.dynamic {@vm.deposit_button} />
            </div>
            <%= if @balance do %>
              <.balance_view {@balance} />
            <% end %>
            <Text.title3 margin="">
              <%= dgettext("eyra-budget", "linked.assignments.title") %>
              <span class="text-primary"> <%= Enum.count(@advert_items) %></span>
            </Text.title3>
            <.list items={@advert_items} />
          </div>
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
