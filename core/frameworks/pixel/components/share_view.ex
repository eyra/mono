defmodule Frameworks.Pixel.ShareView do
  use CoreWeb, :live_component

  alias Core.ImageHelpers
  alias Frameworks.Pixel.UserListItem
  alias Frameworks.Pixel.Button
  alias Systems.Account

  @impl true
  def update(
        %{
          id: id,
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
        content_name: content_name,
        group_name: group_name,
        users: users,
        filtered_users: users,
        shared_users: shared_users,
        users: users,
        close_button: close_button
      )
      |> update_ui()
    }
  end

  defp update_ui(socket) do
    socket
    |> filter_users()
    |> update_shared_user_items()
    |> update_filtered_user_items()
  end

  defp filter_users(%{assigns: %{users: users, shared_users: shared_users}} = socket) do
    socket
    |> assign(filtered_users: Enum.filter(users, &(not Enum.member?(shared_users, &1))))
  end

  defp update_shared_user_items(
         %{assigns: %{shared_users: shared_users, myself: myself}} = socket
       ) do
    shared_user_items = shared_users |> Enum.map(&map_to_item(&1, :remove, myself))
    assign(socket, shared_user_items: shared_user_items)
  end

  defp update_filtered_user_items(
         %{assigns: %{filtered_users: filtered_users, myself: myself}} = socket
       ) do
    filtered_user_items = filtered_users |> Enum.map(&map_to_item(&1, :add, myself))
    assign(socket, filtered_user_items: filtered_user_items)
  end

  defp map_to_item(%Account.User{} = user, action_type, target) do
    photo_url = ImageHelpers.get_photo_url(user.profile)
    action_button = user_action_button(user, action_type, target)

    %{
      photo_url: photo_url,
      name: user.displayname,
      email: user.email,
      info: nil,
      action_button: action_button
    }
  end

  defp user_action_button(user, :add, target) do
    %{
      action: %{type: :send, event: "add", item: user.id, target: target},
      face: %{type: :icon, icon: :add}
    }
  end

  defp user_action_button(user, :remove, target) do
    %{
      action: %{type: :send, event: "remove", item: user.id, target: target},
      face: %{type: :icon, icon: :remove}
    }
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => user_id},
        %{assigns: %{users: users, shared_users: shared_users}} = socket
      ) do
    {
      :noreply,
      if user = users |> Enum.find(&(&1.id == String.to_integer(user_id))) do
        socket
        |> assign(shared_users: [user] ++ shared_users)
        |> update_ui()
        |> send_event(:parent, "add_user", %{user: user})
      else
        socket
      end
    }
  end

  @impl true
  def handle_event(
        "remove",
        %{"item" => user_id},
        %{assigns: %{shared_users: shared_users}} = socket
      ) do
    {
      :noreply,
      if user = shared_users |> Enum.find(&(&1.id == String.to_integer(user_id))) do
        socket
        |> assign(shared_users: shared_users |> List.delete(user))
        |> update_ui()
        |> send_event(:parent, "remove_user", %{user: user})
      else
        socket
      end
    }
  end

  @impl true
  def handle_event("close", _unsigned_params, socket) do
    {:noreply, socket |> send_event(:parent, "finish")}
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
      <.spacing value="S" />
      <div class="rounded border-2 border-grey3 h-40 overflow-scroll">
        <div class="p-4 flex flex-col gap-3">
          <%= for user_item <- @shared_user_items do %>
            <table class="w-full">
              <UserListItem.small {user_item} />
            </table>
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
          <%= for user_item <- @filtered_user_items do %>
            <table class="w-full">
              <UserListItem.small {user_item} />
            </table>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
