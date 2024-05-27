defmodule Systems.Admin.SystemView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Square

  alias Systems.Budget
  alias Systems.Citizen

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          user: user,
          locale: locale,
          bank_accounts: bank_accounts,
          bank_account_items: bank_account_items,
          citizen_pools: citizen_pools,
          citizen_pool_items: citizen_pool_items
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        locale: locale,
        bank_accounts: bank_accounts,
        bank_account_items: bank_account_items,
        citizen_pools: citizen_pools,
        citizen_pool_items: citizen_pool_items
      )
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

  @impl true
  def handle_event("saved", %{source: %{name: popup}}, socket) do
    {:noreply, socket |> hide_popup(popup)}
  end

  @impl true
  def handle_event("cancelled", %{source: %{name: popup}}, socket) do
    {:noreply, socket |> hide_popup(popup)}
  end

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
