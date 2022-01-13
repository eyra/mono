defmodule Frameworks.Pixel.ShareView do
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.UserListItemSmall

  prop(content_id, :number, required: true)
  prop(content_name, :string, required: true)
  prop(group_name, :string, required: true)
  prop(users, :list, required: true)
  prop(shared_users, :list)

  data(filtered_users, :list)
  data(close_button, :map)

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
    send(self(), {:share_view, message})
    socket
  end

  @impl true
  def render(assigns) do
    ~F"""
      <div class="p-8 bg-white shadow-2xl rounded" phx-click="reset_focus" phx-target={@myself}>
        <div class="">
          <div class="flex flex-row">
            <div class="flex-grow">
              <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
                Shared with
              </div>
            </div>
            <DynamicButton vm={@close_button} />
          </div>
          <Spacing value="S" />
          <div class="rounded border-2 border-grey3 h-40 overflow-scroll">
            <div class="p-4 flex flex-col gap-3">
              <div :for={user <- @shared_users} class="flex flex-row items-center gap-3">
                <UserListItemSmall user={user} action_button={%{
                  action: %{type: :send, event: "remove", item: user.id, target: @myself},
                  face: %{type: :icon, icon: :remove}
                }} />
              </div>
            </div>
          </div>
          <Spacing value="L" />

          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            {String.capitalize(@group_name)}
          </div>
          <Spacing value="S" />
          <div class="text-bodymedium font-body sm:text-bodylarge">
            {dgettext("eyra-ui", "share.dialog.text", content: @content_name, group: @group_name)}
          </div>
          <Spacing value="M" />
          <div class="rounded border-2 border-grey3 h-40 overflow-scroll">
            <div class="p-4 flex flex-col gap-3">
              <div :for={user <- @filtered_users} class="flex flex-row items-center gap-3">
                <UserListItemSmall user={user} action_button={%{
                  action: %{type: :send, event: "add", item: user.id, target: @myself},
                  face: %{type: :icon, icon: :add}
                }} />
              </div>
            </div>
          </div>
        </div>
      </div>
    """
  end
end

defmodule Frameworks.Pixel.ShareView.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.ShareView,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Share view",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  data(users, :list,
    default: [
      %{
        id: 2,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{
        id: 3,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{id: 4, profile: %{fullname: Faker.Person.name(), photo_url: nil}},
      %{
        id: 5,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{
        id: 6,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{
        id: 7,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{id: 8, profile: %{fullname: Faker.Person.name(), photo_url: nil}},
      %{id: 9, profile: %{fullname: Faker.Person.name(), photo_url: nil}},
      %{
        id: 10,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      },
      %{
        id: 11,
        profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url(32, 32)}
      }
    ]
  )

  data(shared_users, :list,
    default: [
      %{id: 1, profile: %{fullname: Faker.Person.name(), photo_url: Faker.Avatar.image_url()}}
    ]
  )

  def render(assigns) do
    ~F"""
    <ShareView
      id={:share_view_example}
      content_id={1}
      content_name="campaign"
      group_name="researchers"
      users={@users}
      shared_users={@shared_users}
    />
    """
  end

  def handle_info({:share_view, :close}, socket) do
    IO.puts("Close")
    {:noreply, socket}
  end

  def handle_info({:share_view, %{add: user}}, socket) do
    IO.puts("Add: #{user.fullname}")
    {:noreply, socket}
  end

  def handle_info({:share_view, %{remove: user}}, socket) do
    IO.puts("Remove: #{user.fullname}")
    {:noreply, socket}
  end
end
