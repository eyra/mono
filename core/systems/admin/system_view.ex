defmodule Systems.Admin.SystemView do
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Square

  alias Systems.Admin.SystemViewBuilder
  alias Systems.Observatory

  def dependencies(),
    do: [
      :current_user,
      :locale,
      :bank_accounts,
      :bank_account_items,
      :citizen_pools,
      :citizen_pool_items
    ]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "edit_bank_account",
        %{"item" => item},
        %{assigns: %{current_user: user, vm: %{bank_accounts: bank_accounts}}} = socket
      ) do
    bank_account = Enum.find(bank_accounts, &(&1.id == String.to_integer(item)))
    modal = SystemViewBuilder.build_bank_account_modal(bank_account, user)

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_event(
        "create_bank_account",
        _,
        %{assigns: %{current_user: user}} = socket
      ) do
    modal = SystemViewBuilder.build_bank_account_modal(nil, user)

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_event(
        "edit_citizen_pool",
        %{"item" => item},
        %{assigns: %{current_user: user, locale: locale, vm: %{citizen_pools: citizen_pools}}} =
          socket
      ) do
    pool = Enum.find(citizen_pools, &(&1.id == String.to_integer(item)))
    modal = SystemViewBuilder.build_citizen_pool_modal(pool, user, locale)

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_event(
        "create_citizen_pool",
        _,
        %{assigns: %{current_user: user, locale: locale}} = socket
      ) do
    modal = SystemViewBuilder.build_citizen_pool_modal(nil, user, locale)

    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="system-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @vm.bank_accounts_title %> <span class="text-primary"><%= @vm.bank_account_count %></span></Text.title2>
        <Square.container>
          <Square.item
            state={:transparent}
            title={@vm.bank_accounts_new_title}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_bank_account", item: "first"}}
          />
          <%= for bank_account_item <- @vm.bank_account_items do %>
            <Square.item {bank_account_item} />
          <% end %>
        </Square.container>
        <.spacing value="XL" />

        <Text.title2><%= @vm.citizen_pools_title %> <span class="text-primary"><%= @vm.citizen_pool_count %></span></Text.title2>
        <Square.container>
          <Square.item
            state={:transparent}
            title={@vm.citizen_pools_new_title}
            icon={{:static, "add_tertiary"}}
            action={%{type: :send, event: "create_citizen_pool", item: "first"}}
          />
          <%= for citizen_pool_item <- @vm.citizen_pool_items do %>
            <Square.item {citizen_pool_item} />
          <% end %>
        </Square.container>
      </Area.content>
    </div>
    """
  end
end
