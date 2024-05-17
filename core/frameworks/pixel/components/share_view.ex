defmodule Frameworks.Pixel.ShareView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.UserListItem
  alias Frameworks.Pixel.Button

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
        %{assigns: %{users: users, shared_users: shared_users}} = socket
      ) do
    {
      :noreply,
      if user = users |> Enum.find(&(&1.id == String.to_integer(user_id))) do
        socket
        |> assign(shared_users: [user] ++ shared_users)
        |> filter_users()
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
        |> filter_users()
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
      <Frameworks.Pixel.Panel.flat>
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
      </Frameworks.Pixel.Panel.flat>
    </div>
    """
  end
end
