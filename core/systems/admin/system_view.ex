defmodule Systems.Admin.SystemView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Square

  alias Systems.Pool
  alias Systems.Budget
  alias Systems.Citizen

  # Initial update
  @impl true
  def update(%{id: id, user: user, locale: locale}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        locale: locale
      )
      |> update_bank_accounts()
      |> update_citizen_pools()
    }
  end

  @impl true
  def compose(:pool_form, %{user: user, locale: locale, active_pool: pool}) do
    %{
      module: Citizen.Pool.Form,
      params: %{
        pool: pool,
        user: user,
        locale: locale
      }
    }
  end

  @impl true
  def compose(:bank_account_form, %{user: user, locale: locale, active_bank_account: bank_account}) do
    %{
      module: Budget.BankAccountForm,
      params: %{
        bank_account: bank_account,
        user: user,
        locale: locale
      }
    }
  end

  defp update_bank_accounts(%{assigns: %{locale: locale, myself: target, user: _user}} = socket) do
    bank_accounts = Budget.Public.list_bank_accounts(Budget.BankAccountModel.preload_graph(:full))

    bank_account_items = Enum.map(bank_accounts, &to_view_model(&1, target, locale))

    socket
    |> assign(
      bank_accounts: bank_accounts,
      bank_account_items: bank_account_items
    )
  end

  defp update_citizen_pools(%{assigns: %{locale: locale, myself: target, user: _user}} = socket) do
    citizen_pools = Citizen.Public.list_pools(currency: Budget.CurrencyModel.preload_graph(:full))

    citizen_pool_items = Enum.map(citizen_pools, &to_view_model(&1, target, locale))

    socket
    |> assign(
      citizen_pools: citizen_pools,
      citizen_pool_items: citizen_pool_items
    )
  end

  defp to_view_model(
         %Budget.BankAccountModel{id: id, name: name, icon: icon, currency: currency},
         target,
         locale
       ) do
    subtitle = Budget.CurrencyModel.title(currency, locale)

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "edit_bank_account", item: id, target: target}
    }
  end

  defp to_view_model(
         %Pool.Model{id: id, name: name, icon: icon, currency: currency},
         target,
         locale
       ) do
    subtitle = Budget.CurrencyModel.title(currency, locale)

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "edit_citizen_pool", item: id, target: target}
    }
  end

  @impl true
  def handle_event(
        "edit_bank_account",
        %{"item" => item},
        %{assigns: %{bank_accounts: bank_accounts}} = socket
      ) do
    bank_account = Enum.find(bank_accounts, &(&1.id == String.to_integer(item)))

    {
      :noreply,
      socket
      |> assign(active_bank_account: bank_account)
      |> compose_child(:bank_account_form)
      |> show_popup(:bank_account_form)
    }
  end

  @impl true
  def handle_event("create_bank_account", _, socket) do
    {
      :noreply,
      socket
      |> assign(active_bank_account: nil)
      |> compose_child(:bank_account_form)
      |> show_popup(:bank_account_form)
    }
  end

  @impl true
  def handle_event(
        "edit_citizen_pool",
        %{"item" => item},
        %{assigns: %{citizen_pools: citizen_pools}} = socket
      ) do
    pool = Enum.find(citizen_pools, &(&1.id == String.to_integer(item)))

    {
      :noreply,
      socket
      |> assign(active_pool: pool)
      |> compose_child(:pool_form)
      |> show_popup(:pool_form)
    }
  end

  @impl true
  def handle_event("create_citizen_pool", _, socket) do
    {
      :noreply,
      socket
      |> assign(active_pool: nil)
      |> compose_child(:pool_form)
      |> show_popup(:pool_form)
    }
  end

  attr(:user, :list, required: true)
  attr(:locale, :list, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-admin", "system.bank.accounts.title") %> <span class="text-primary"><%= Enum.count(@bank_account_items) %></span></Text.title2>
        <Square.container>
          <Square.item
            state={:transparent}
            title={dgettext("eyra-admin", "system.bank.accounts.new.title")}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_bank_account", item: "first", target: @myself}}
          />
          <%= for bank_account_item <- @bank_account_items do %>
            <Square.item {bank_account_item} />
          <% end %>
        </Square.container>
        <.spacing value="XL" />

        <Text.title2><%= dgettext("eyra-admin", "system.citizen.pools.title") %> <span class="text-primary"><%= Enum.count(@citizen_pool_items) %></span></Text.title2>
        <Square.container>
          <Square.item
            state={:transparent}
            title={dgettext("eyra-admin", "system.citizen.pools.new.title")}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_citizen_pool", item: "first", target: @myself}}
          />
          <%= for citizen_pool_item <- @citizen_pool_items do %>
            <Square.item {citizen_pool_item} />
          <% end %>
        </Square.container>
      </Area.content>
    </div>
    """
  end
end
