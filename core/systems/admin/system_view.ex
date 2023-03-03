defmodule Systems.Admin.SystemView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.{Square, SquareContainer}

  alias Systems.{
    Budget,
    Citizen,
    Pool
  }

  prop(props, :any)

  data(bank_accounts, :list)
  data(bank_account_items, :list)

  data(citizen_pools, :list)
  data(citizen_pool_items, :list)

  # Popup cancel
  def update(%{module: _, action: "cancel"}, socket) do
    {
      :ok,
      socket
      |> hide_popup()
    }
  end

  # Popup saved
  def update(%{module: _, action: "saved"}, socket) do
    {
      :ok,
      socket
      |> update_bank_accounts()
      |> update_citizen_pools()
      |> hide_popup()
    }
  end

  # Initial update
  def update(%{id: id, props: %{user: user, locale: locale}}, socket) do
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

  def handle_event(
        "edit_bank_account",
        %{"item" => item},
        %{assigns: %{id: id, user: user, locale: locale, bank_accounts: bank_accounts}} = socket
      ) do
    bank_account = Enum.find(bank_accounts, &(&1.id == String.to_integer(item)))

    popup = %{
      module: Budget.BankAccountForm,
      bank_account: bank_account,
      user: user,
      locale: locale,
      target: %{type: __MODULE__, id: id}
    }

    {:noreply, socket |> show_popup(popup)}
  end

  def handle_event(
        "create_bank_account",
        _,
        %{assigns: %{id: id, user: user, locale: locale}} = socket
      ) do
    popup = %{
      module: Budget.BankAccountForm,
      bank_account: nil,
      user: user,
      locale: locale,
      target: %{type: __MODULE__, id: id}
    }

    {:noreply, socket |> show_popup(popup)}
  end

  def handle_event(
        "edit_citizen_pool",
        %{"item" => item},
        %{assigns: %{id: id, user: user, locale: locale, citizen_pools: citizen_pools}} = socket
      ) do
    pool = Enum.find(citizen_pools, &(&1.id == String.to_integer(item)))

    popup = %{
      module: Citizen.Pool.Form,
      pool: pool,
      user: user,
      locale: locale,
      target: %{type: __MODULE__, id: id}
    }

    {:noreply, socket |> show_popup(popup)}
  end

  def handle_event(
        "create_citizen_pool",
        _,
        %{assigns: %{id: id, user: user, locale: locale}} = socket
      ) do
    popup = %{
      module: Citizen.Pool.Form,
      pool: nil,
      user: user,
      locale: locale,
      target: %{type: __MODULE__, id: id}
    }

    {:noreply, socket |> show_popup(popup)}
  end

  defp show_popup(socket, popup) do
    send(self(), {:show_popup, popup})
    socket
  end

  defp hide_popup(socket) do
    send(self(), {:hide_popup})
    socket
  end

  def render(assigns) do
    ~F"""
    <div>
      <ContentArea>
        <MarginY id={:page_top} />
        <Title2>{dgettext("eyra-admin", "system.bank.accounts.title")} <span class="text-primary">{Enum.count(@bank_account_items)}</span></Title2>
        <SquareContainer>
          <Square
            state={:transparent}
            title={dgettext("eyra-admin", "system.bank.accounts.new.title")}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_bank_account", item: "first", target: @myself}}
          />
          <Square :for={bank_account_item <- @bank_account_items} {...bank_account_item} />
        </SquareContainer>
        <Spacing value="XL" />

        <Title2>{dgettext("eyra-admin", "system.citizen.pools.title")} <span class="text-primary">{Enum.count(@citizen_pool_items)}</span></Title2>
        <SquareContainer>
          <Square
            state={:transparent}
            title={dgettext("eyra-admin", "system.citizen.pools.new.title")}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_citizen_pool", item: "first", target: @myself}}
          />
          <Square :for={citizen_pool_item <- @citizen_pool_items} {...citizen_pool_item} />
        </SquareContainer>
      </ContentArea>
    </div>
    """
  end
end
