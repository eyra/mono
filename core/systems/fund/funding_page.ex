defmodule Systems.Fund.FundingPage do
  use Systems.Content.Composer, :live_workspace

  import Frameworks.Pixel.Content
  import Frameworks.Pixel.Line
  import Systems.Fund.BalanceView

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Square
  alias Systems.Fund
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
      |> assign(selected_fund: nil)
      |> update_funds()
      |> update_selected_fund()
      |> update_balance()
      |> update_squares()
      |> update_adverts()
    }
  end

  @impl true
  def compose(:create_fund_form, %{user: user, locale: locale}) do
    %{
      module: Systems.Fund.Form,
      params: %{
        fund: nil,
        user: user,
        locale: locale
      }
    }
  end

  @impl true
  def compose(:edit_fund_form, %{selected_fund: selected_fund, user: user, locale: locale}) do
    %{
      module: Systems.Fund.Form,
      params: %{
        fund: selected_fund,
        user: user,
        locale: locale
      }
    }
  end

  @impl true
  def compose(:fund_deposit_form, %{selected_fund: selected_fund}) do
    %{
      module: Systems.Fund.DepositForm,
      params: %{fund: selected_fund}
    }
  end

  defp update_adverts(%{assigns: %{selected_fund: nil}} = socket) do
    socket |> assign(advert_items: [])
  end

  defp update_adverts(%{assigns: %{selected_fund: selected_fund} = assigns} = socket) do
    advert_items =
      selected_fund
      |> Advert.Public.list_by_fund(Advert.Model.preload_graph(:down))
      |> Enum.map(&to_content_list_item(&1, assigns))

    socket |> assign(advert_items: advert_items)
  end

  defp to_content_list_item(advert, assigns) do
    ViewModelBuilder.view_model(advert, {__MODULE__, :fund_adverts}, assigns)
  end

  defp update_funds(%{assigns: %{current_user: user}} = socket) do
    funds =
      Fund.Public.list_owned(user, [
        :available,
        :pending,
        currency: Fund.CurrencyModel.preload_graph(:full)
      ])
      |> Enum.filter(&(&1.currency.type == :legal))

    socket |> assign(funds: funds)
  end

  defp update_selected_fund(%{assigns: %{funds: funds, selected_fund: nil}} = socket) do
    fund = List.first(funds)
    socket |> assign(selected_fund: fund)
  end

  defp update_selected_fund(
         %{assigns: %{funds: funds, selected_fund: %{id: selected_id}}} = socket
       ) do
    fund = Enum.find(funds, &(&1.id == selected_id))
    socket |> assign(selected_fund: fund)
  end

  defp update_balance(%{assigns: %{selected_fund: nil}} = socket) do
    socket |> assign(balance: nil)
  end

  defp update_balance(
         %{assigns: %{selected_fund: %{currency: currency} = fund, locale: locale}} = socket
       ) do
    available = Fund.Model.amount_available(fund)
    reserved = Fund.Model.amount_reserved(fund)
    spend = Fund.Model.amount_spend(fund)

    balance = %{
      available: Fund.CurrencyModel.label(currency, locale, available),
      reserved: Fund.CurrencyModel.label(currency, locale, reserved),
      spend: Fund.CurrencyModel.label(currency, locale, spend),
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
         %{assigns: %{funds: funds, selected_fund: selected_fund, locale: locale}} =
           socket
       ) do
    socket |> assign(squares: Enum.map(funds, &to_square(&1, selected_fund, locale)))
  end

  defp to_square(
         %Fund.Model{id: id, name: name, available: available, currency: currency, icon: icon} = _fund,
         %{id: selected_id},
         locale
       ) do
    %{debit: debit, credit: credit} = Bookkeeping.Public.balance(available)
    subtitle = Fund.CurrencyModel.label(currency, locale, credit - debit)

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
      action: %{type: :send, event: "select_fund", item: id, target: false},
      state: state
    }
  end

  # Events

  @impl true
  def handle_event("create_fund", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:create_fund_form)
      |> Fabric.ModalController.show_modal(:create_fund_form, :compact)
    }
  end

  @impl true
  def handle_event("edit_fund", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:edit_fund_form)
      |> Fabric.ModalController.show_modal(:edit_fund_form, :compact)
    }
  end

  @impl true
  def handle_event("deposit_money", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:fund_deposit_form)
      |> Fabric.ModalController.show_modal(:fund_deposit_form, :compact)
    }
  end

  @impl true
  def handle_event(
        "select_fund",
        %{"item" => fund_id},
        %{assigns: %{funds: funds}} = socket
      ) do
    selected_fund = funds |> Enum.find(&(&1.id == String.to_integer(fund_id)))

    {
      :noreply,
      socket
      |> assign(selected_fund: selected_fund)
      |> update_balance()
      |> update_squares()
      |> update_adverts()
    }
  end

  @impl true
  def handle_event("deposit_saved", %{source: %{name: modal_id}}, socket) do
    {
      :noreply,
      socket
      |> update_funds()
      |> update_selected_fund()
      |> update_balance()
      |> update_squares()
      |> Fabric.ModalController.hide_modal(modal_id)
    }
  end

  @impl true
  def handle_event(
        "fund_saved",
        %{source: %{name: modal_id, module: Systems.Fund.Form}},
        socket
      ) do
    {
      :noreply,
      socket
      |> update_funds()
      |> update_selected_fund()
      |> update_balance()
      |> update_squares()
      |> hide_modal(modal_id)
    }
  end

  @impl true
  def handle_event("fund_cancelled", %{source: %{name: modal_id}}, socket) do
    {
      :noreply,
      socket
      |> Fabric.ModalController.hide_modal(modal_id)
    }
  end

  @impl true
  def handle_event("deposit_cancelled", %{source: %{name: modal_id}}, socket) do
    {:noreply, socket |> Fabric.ModalController.hide_modal(modal_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-fund", "funding.title")} menus={@menus}>
      <Margin.y id={:page_top} />
      <Area.content>
        <Text.title1>
          <%= dgettext("eyra-fund", "funding.funds.title") %>
          <span class="text-primary"><%= Enum.count(@squares) %></span>
        </Text.title1>
        <Square.container>
          <Square.item {@vm.create_fund} />
          <%= for square <- @squares do %>
            <Square.item {square} />
          <% end %>
        </Square.container>
        <%= if @selected_fund do %>
          <div class="flex flex-col gap-10">
            <div />
            <.line />
            <div class="flex flex-row gap-8">
              <Text.title2 margin=""><%= @selected_fund.name %></Text.title2>
              <div class="flex-grow" />
              <Button.dynamic {@vm.edit_button} />
              <Button.dynamic {@vm.deposit_button} />
            </div>
            <%= if @balance do %>
              <.balance_view {@balance} />
            <% end %>
            <Text.title3 margin="">
              <%= dgettext("eyra-fund", "linked.assignments.title") %>
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
