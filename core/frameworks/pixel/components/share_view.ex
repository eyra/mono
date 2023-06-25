defmodule Frameworks.Pixel.ShareView do
  use CoreWeb, :live_component

  alias CoreWeb.UI.UserListItem
  alias Frameworks.Pixel.SearchBar

  @impl true
  def update(
        %{
          id: id,
          content_id: content_id,
          content_name: content_name,
          group_name: group_name,
          users: users,
          shared_users: shared_users
        },
        %{assigns: %{myself: myself}} = socket
      ) do
    close_button = %{
      action: %{type: :send, event: "close", target: myself},
      face: %{type: :icon, icon: :close}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        content_id: content_id,
        content_name: content_name,
        group_name: group_name,
        users: users,
        filtered_users: users,
        shared_users: shared_users,
        users: users,
        close_button: close_button,
        query_string: ""
      )
      |> filter_users()
    }
  end

  defp filter_users(%{assigns: %{users: users, shared_users: shared_users}} = socket) do
    socket
    |> assign(filtered_users: Enum.filter(users, &(not Enum.member?(shared_users, &1))))
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => user_id},
        %{assigns: %{users: users, shared_users: shared_users, content_id: content_id}} = socket
      ) do
    {
      :noreply,
      if user = users |> Enum.find(&(&1.id == String.to_integer(user_id))) do
        socket
        |> assign(shared_users: [user] ++ shared_users)
        |> filter_users()
        |> update_parent(%{add: user, content_id: content_id})
      else
        socket
      end
    }
  end

  @impl true
  def handle_event(
        "remove",
        %{"item" => user_id},
        %{assigns: %{shared_users: shared_users, content_id: content_id}} = socket
      ) do
    {
      :noreply,
      if user = shared_users |> Enum.find(&(&1.id == String.to_integer(user_id))) do
        socket
        |> assign(shared_users: shared_users |> List.delete(user))
        |> filter_users()
        |> update_parent(%{remove: user, content_id: content_id})
      else
        socket
      end
    }
  end

  @impl true
  def handle_event("close", _unsigned_params, socket) do
    {:noreply, update_parent(socket, :close)}
  end

  defp update_parent(socket, message) do
    send(self(), %{module: __MODULE__, action: message})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="">
      <div class="flex flex-row">
        <div class="flex-grow">
          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            <%= dgettext("eyra-ui", "share.dialog.title") %>
          </div>
        </div>
        <Button.dynamic {@close_button} />
      </div>

      <.live_component
        module={SearchBar}
        id={:share_search_bar}
        query_string={@query_string}
        placeholder={dgettext("eyra-ui", "share.search.placeholder")}
        debounce="200"
        parent={%{type: __MODULE__, id: @id}}
      />

      <.spacing value="S" />
      <div class="rounded border-2 border-grey3 h-40 overflow-scroll">
        <div class="p-4 flex flex-col gap-3">
          <%= for user <- @shared_users do %>
            <div class="flex flex-row items-center gap-3">
              <UserListItem.small
                user={user}
                action_button={%{
                  action: %{type: :send, event: "remove", item: user.id, target: @myself},
                  face: %{type: :icon, icon: :remove}
                }}
              />
            </div>
          <% end %>
        </div>
      </div>
      <.spacing value="L" />

      <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
        <%= String.capitalize(@group_name) %>
      </div>
      <.spacing value="S" />
      <div class="text-bodymedium font-body sm:text-bodylarge">
        <%= dgettext("eyra-ui", "share.dialog.text", content: @content_name, group: @group_name) %>
      </div>
      <.spacing value="M" />
      <div class="rounded border-2 border-grey3 h-40 overflow-scroll">
        <div class="p-4 flex flex-col gap-3">
          <%= for user <- @filtered_users do %>
            <div class="flex flex-row items-center gap-3">
              <UserListItem.small
                user={user}
                action_button={%{
                  action: %{type: :send, event: "add", item: user.id, target: @myself},
                  face: %{type: :icon, icon: :add}
                }}
              />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
