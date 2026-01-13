defmodule Systems.Account.PeopleEditorComponent do
  @moduledoc """
  Reusable LiveComponent for managing a list of people (add/remove).

  Features:
  - Display list of current people with remove buttons
  - Search by email to add new people
  - Self-removal confirmation (when removing yourself)
  - Sends `add_user` and `remove_user` events to parent

  ## Usage

      <.live_component
        module={Account.PeopleEditorComponent}
        id="people_editor"
        title="Members"
        people={@members}
        users={@available_users}
        current_user={@current_user}
      />

  ## Events sent to parent
  - `{:add_user, %{user: user}}` - when a user is added
  - `{:remove_user, %{user: user}}` - when a user is removed
  """
  use Phoenix.LiveComponent
  use Gettext, backend: CoreWeb.Gettext

  import CoreWeb.UI.Spacing, only: [spacing: 1]

  alias Core.ImageHelpers
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.UserListItem
  alias Systems.Account.PeopleHelpers

  @impl true
  def update(%{search_query: %{query_string: query_string}}, socket) do
    query_string = String.trim(query_string)

    {:ok,
     socket
     |> assign(:query_string, query_string)
     |> update_user_item()
     |> update_search_message()}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query_string, fn -> "" end)
      |> assign_new(:confirm_removal_user_ids, fn -> MapSet.new() end)
      |> assign_new(:user_item, fn -> nil end)
      |> assign_new(:message, fn -> nil end)

    {:ok,
     socket
     |> update_people_items()
     |> update_search_message()}
  end

  @impl true
  def handle_event("add", %{"item" => user_id_string}, socket) do
    user_id = String.to_integer(user_id_string)
    %{users: users, people: people} = socket.assigns

    case Enum.find(users, &(&1.id == user_id)) do
      nil ->
        {:noreply, socket}

      user ->
        new_users = Enum.reject(users, &(&1.id == user_id))
        new_people = people ++ [user]

        send(self(), {:add_user, %{user: user}})

        {:noreply,
         socket
         |> assign(users: new_users, people: new_people)
         |> assign(query_string: "", user_item: nil)
         |> update_people_items()
         |> update_search_message()}
    end
  end

  @impl true
  def handle_event("remove", %{"item" => user_id_string}, socket) do
    user_id = String.to_integer(user_id_string)
    %{people: people, current_user: me, confirm_removal_user_ids: ids} = socket.assigns

    case Enum.find(people, &(&1.id == user_id)) do
      nil ->
        {:noreply, socket}

      user ->
        if user.id == me.id and not MapSet.member?(ids, user.id) do
          # First click on self: show confirmation
          {:noreply,
           socket
           |> assign(:confirm_removal_user_ids, MapSet.put(ids, user.id))
           |> update_people_items()}
        else
          # Confirmed or removing someone else
          finalize_remove(socket, user)
        end
    end
  end

  @impl true
  def handle_event("cancel_remove", %{"item" => user_id_string}, socket) do
    user_id = String.to_integer(user_id_string)
    %{confirm_removal_user_ids: ids} = socket.assigns

    {:noreply,
     socket
     |> assign(:confirm_removal_user_ids, MapSet.delete(ids, user_id))
     |> update_people_items()}
  end

  defp finalize_remove(socket, user) do
    %{users: users, people: people, confirm_removal_user_ids: ids} = socket.assigns

    new_people = Enum.reject(people, &(&1.id == user.id))
    new_users = users ++ [user]

    send(self(), {:remove_user, %{user: user}})

    {:noreply,
     socket
     |> assign(:confirm_removal_user_ids, MapSet.delete(ids, user.id))
     |> assign(users: new_users, people: new_people)
     |> update_people_items()
     |> update_search_message()}
  end

  defp update_people_items(socket) do
    %{people: people, current_user: me, confirm_removal_user_ids: ids, myself: target} =
      socket.assigns

    people_items =
      Enum.map(people, fn person ->
        build_person_item(person, me, Enum.count(people), ids, target)
      end)

    assign(socket, people_items: people_items)
  end

  defp update_user_item(socket) do
    %{query_string: qs, users: users, myself: target} = socket.assigns

    user = find_user_by_email(users, qs)
    user_item = build_search_result_item(user, target)
    assign(socket, user_item: user_item)
  end

  defp update_search_message(%{assigns: %{query_string: ""}} = socket) do
    assign(socket, message: nil)
  end

  defp update_search_message(
         %{assigns: %{user_item: nil, people: people, query_string: qs}} = socket
       )
       when qs != "" do
    message =
      if find_user_by_email(people, qs) do
        dgettext("eyra-account", "people.search.alread_added.message")
      else
        dgettext("eyra-account", "people.search.no_match.message")
      end

    assign(socket, message: message)
  end

  defp update_search_message(socket) do
    assign(socket, message: nil)
  end

  defp find_user_by_email(users, email) do
    Enum.find(users, &(&1.email == String.trim(email)))
  end

  defp build_person_item(user, me, people_count, confirm_ids, target) do
    photo_url = ImageHelpers.get_photo_url(user.profile)

    base_item = %{
      photo_url: photo_url,
      name: user.displayname,
      email: user.email
    }

    if user.id == me.id and MapSet.member?(confirm_ids, user.id) do
      # Show confirmation row for self-removal
      base_item
      |> Map.put(:action_buttons, [])
      |> Map.merge(PeopleHelpers.build_confirm_row(user.id, target))
    else
      Map.put(base_item, :action_buttons, build_remove_buttons(user, people_count, target))
    end
  end

  defp build_remove_buttons(_user, 1, _target), do: []

  defp build_remove_buttons(user, _count, target) do
    [
      %{
        action: %{type: :send, event: "remove", item: user.id, target: target},
        face: %{type: :icon, icon: :remove}
      }
    ]
  end

  defp build_search_result_item(nil, _target), do: nil

  defp build_search_result_item(user, target) do
    photo_url = ImageHelpers.get_photo_url(user.profile)

    %{
      id: user.id,
      photo_url: photo_url,
      name: user.displayname,
      email: user.email,
      action_buttons: [
        %{
          action: %{type: :send, event: "add", item: user.id, target: target},
          face: %{type: :plain, label: dgettext("eyra-account", "people.add.button"), icon: :add}
        }
      ]
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <Text.title2><%= @title %> <span class="text-primary"><%= Enum.count(@people) %></span></Text.title2>

      <div class="flex flex-col gap-8">
        <%= if @people_items != [] do %>
          <div class="py-3 px-6 border-2 border-grey4 rounded overflow-y-scroll max-h-[40vh]">
            <table class="w-full">
              <%= for people_item <- @people_items do %>
                <.live_component module={UserListItem} id={"person-#{people_item.email}"} people_item={people_item} />
              <% end %>
            </table>
          </div>
        <% end %>

        <div>
          <Text.title5 align="text-left">
            <%= dgettext("eyra-account", "people.add.title") %>
          </Text.title5>
          <.spacing value="XS" />

          <.live_component
            module={SearchBar}
            id={"#{@id}_search_bar"}
            query_string={@query_string}
            placeholder={dgettext("eyra-account", "people.search.placeholder")}
            debounce="200"
            target={{__MODULE__, @id}}
          />

          <%= if @user_item do %>
            <.spacing value="S" />
            <div class="py-3 px-6 border-2 border-grey4 rounded">
              <table class="w-full">
                <.live_component module={UserListItem} id={"search-#{@user_item.id}"} user_item={@user_item} />
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
          <% end %>
        </div>
      </div>

      <div class="flex-grow" />
    </div>
    """
  end
end
