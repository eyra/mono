defmodule Systems.Account.PeopleView do
  use CoreWeb.LiveForm

  alias Core.ImageHelpers
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.UserListItem
  alias Systems.Account

  @impl true
  def update(%{users: users, people: people, title: title}, socket) do
    query = Map.get(socket.assigns, :query, [])
    query_string = Map.get(socket.assigns, :query_string, "")

    {
      :ok,
      socket
      |> assign(
        users: users,
        user_item: nil,
        people: people,
        title: title,
        query: query,
        query_string: query_string
      )
      |> update_people_items()
      |> update_message()
      |> compose_child(:search_bar)
    }
  end

  defp update_message(%{assigns: %{query_string: ""}} = socket) do
    assign(socket, message: nil)
  end

  defp update_message(
         %{assigns: %{user_item: nil, people: people, query_string: query_string}} = socket
       ) do
    message =
      if find_by_email(people, query_string) do
        dgettext("eyra-account", "people.search.alread_added.message")
      else
        dgettext("eyra-account", "people.search.no_match.message")
      end

    assign(socket, message: message)
  end

  defp update_message(socket) do
    assign(socket, message: nil)
  end

  defp update_people_items(%{assigns: %{people: people, myself: myself}} = socket) do
    people_items = Enum.map(people, &map_to_item(:people, &1, myself, Enum.count(people)))
    assign(socket, people_items: people_items)
  end

  defp reset_search(socket) do
    assign(socket, query_string: "", user_item: nil)
  end

  defp find_by_email(users, email) do
    Enum.find(users, &(&1.email == String.trim(email)))
  end

  @impl true
  def compose(:search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-account", "people.search.placeholder"),
        debounce: "200"
      }
    }
  end

  @impl true
  def handle_event(
        "search_query",
        %{query_string: query_string, source: %{name: :search_bar}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(query_string: query_string)
      |> update_user()
      |> update_message()
    }
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => user_id},
        %{assigns: %{users: users, people: people}} = socket
      ) do
    user_id = String.to_integer(user_id)

    socket =
      if user = Enum.find(users, &(&1.id == user_id)) do
        users = Enum.reject(users, &(&1.id == user_id))
        people = people ++ [user]

        socket
        |> assign(users: users, people: people)
        |> reset_search()
        |> update_people_items()
        |> update_message()
        |> send_event(:parent, "add_user", %{user: user})
      else
        socket |> flash_error()
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove", _, %{assigns: %{people: [_]}} = socket) do
    {:noreply, socket |> flash_error()}
  end

  @impl true
  def handle_event(
        "remove",
        %{"item" => user_id},
        %{assigns: %{users: users, people: people}} = socket
      ) do
    user_id = String.to_integer(user_id)

    socket =
      if user = Enum.find(people, &(&1.id == user_id)) do
        people = Enum.reject(people, &(&1.id == user_id))
        users = users ++ [user]

        socket
        |> assign(users: users, people: people)
        |> update_people_items()
        |> update_message()
        |> send_event(:parent, "remove_user", %{user: user})
      else
        socket |> flash_error()
      end

    {:noreply, socket}
  end

  defp update_user(
         %{assigns: %{query_string: query_string, users: users, myself: myself}} = socket
       ) do
    user = find_by_email(users, query_string)
    user_item = map_to_item(:search, user, myself, 1)

    socket
    |> assign(user: user, user_item: user_item)
  end

  defp map_to_item(type, %Account.User{} = user, target, count) do
    photo_url = ImageHelpers.get_photo_url(user.profile)
    action_button = user_action_button(type, user, target, count)

    %{
      photo_url: photo_url,
      name: user.displayname,
      email: user.email,
      action_button: action_button
    }
  end

  defp map_to_item(_, nil, _, _), do: nil

  defp user_action_button(:people, _, _, count) when count <= 1 do
    nil
  end

  defp user_action_button(:people, %Account.User{} = user, target, _) do
    %{
      action: %{type: :send, event: "remove", item: user.id, target: target},
      face: %{type: :icon, icon: :remove}
    }
  end

  defp user_action_button(:search, %Account.User{} = user, target, _) do
    %{
      action: %{type: :send, event: "add", item: user.id, target: target},
      face: %{type: :plain, label: "Add", icon: :add}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-10 h-full">
      <div class="py-3 px-6 border-2 border-grey4 rounded overflow-y-scroll">
        <table class="w-full">
          <%= for people_item <- @people_items do %>
            <UserListItem.small {people_item} />
          <% end %>
        </table>
      </div>
      <div>
        <Text.title5 align="text-left"><%= dgettext("eyra-account", "people.add.title") %></Text.title5>
        <.spacing value="XS" />
        <.child name={:search_bar} fabric={@fabric} />
        <%= if @user_item do %>
          <.spacing value="S" />
          <div class="py-3 px-6 border-2 border-grey4 rounded">
            <table class="w-full">
              <UserListItem.small {@user_item} />
            </table>
          </div>
        <% end %>
        <%= if @message do %>
          <.spacing value="S" />
          <div class="py-3 px-6 border-2 border-grey4 rounded">
            <div class="h-12 flex flex-col justify-center">
              <Text.body_medium><%= @message %></Text.body_medium>
            </div>
          </div>
        <% else %>
          <.spacing value="XS" />
        <% end %>
      </div>
      <div class="flex-grow" />
    </div>
    """
  end
end
