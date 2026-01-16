defmodule Systems.Admin.AccountView do
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.UserListItem

  alias Systems.Account
  alias Systems.Observatory

  def dependencies(), do: []

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {
      :ok,
      socket
      |> assign(query_string: "")
    }
  end

  defp save(socket, user_id_string, attrs) do
    user = Account.Public.get_user!(String.to_integer(user_id_string))
    changeset = Account.User.admin_changeset(user, attrs)
    {:ok, _} = Core.Persister.save(user, changeset)
    socket |> update_view_model()
  end

  # Events

  @impl true
  def handle_event("make_creator", %{"item" => user_id_string}, socket) do
    {:noreply, socket |> save(user_id_string, %{creator: true})}
  end

  @impl true
  def handle_event("verify_creator", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{creator: true, verified_at: NaiveDateTime.utc_now()})
    }
  end

  @impl true
  def handle_event("unverify_creator", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{verified_at: nil})
    }
  end

  @impl true
  def handle_event("activate_user", %{"item" => user_id_string}, socket) do
    {
      :noreply,
      socket |> save(user_id_string, %{creator: true, confirmed_at: NaiveDateTime.utc_now()})
    }
  end

  @impl true
  def handle_event("deactivate_user", %{"item" => user_id_string}, socket) do
    {:noreply, socket |> save(user_id_string, %{confirmed_at: nil})}
  end

  @impl true
  def handle_event(
        "search_query",
        %{query: query, query_string: query_string, source: %{name: :account_search_bar}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(query: query, query_string: query_string)
      |> update_view_model()
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_filters, source: %{name: :account_filters}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> update_view_model()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="account-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2 data-testid="account-title">
          <%= @vm.title %> <span class="text-primary"><%= @vm.user_count %></span>
        </Text.title2>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
            <.live_component
              module={Selector}
              id={:account_filters}
              items={@vm.filter_labels}
              type={:label}
            />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.live_component
              module={SearchBar}
              id={:account_search_bar}
              query_string={@query_string}
              placeholder={@vm.search_placeholder}
              debounce="200"
            />
          </div>
        </div>
        <.spacing value="M" />

        <table class="w-full" data-testid="user-list">
          <%= for user_item <- @vm.users do %>
            <.live_component module={UserListItem} id={user_item.email} user_item={user_item} />
          <% end %>
        </table>
      </Area.content>
    </div>
    """
  end
end
