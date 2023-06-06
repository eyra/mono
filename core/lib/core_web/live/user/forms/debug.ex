defmodule CoreWeb.User.Forms.Debug do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Selector

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: :role_selector},
        %{assigns: %{entity: entity}} = socket
      ) do
    attrs =
      [:student, :researcher]
      |> Enum.reduce(%{}, fn field, acc ->
        Map.put(acc, field, field == active_item_id)
      end)

    {
      :ok,
      socket
      |> save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  @impl true
  def update(%{id: id, user: user}, socket) do
    profile = Accounts.get_profile(user)
    entity = UserProfileEdit.create(user, profile)

    role_labels = [
      %{
        id: :student,
        value: "Student",
        active: not entity.researcher
      },
      %{
        id: :researcher,
        value: "Researcher",
        active: entity.researcher
      }
    ]

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(role_labels: role_labels)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    changeset = UserProfileEdit.changeset(entity, :mount, %{})

    socket
    |> assign(changeset: changeset)
  end

  # Saving

  @impl true
  def handle_event(
        "save",
        %{"user_profile_edit" => attrs},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  @impl true
  def handle_event(
        "save",
        _params,
        socket
      ) do
    {
      :noreply,
      socket
    }
  end

  def save(socket, %Core.Accounts.UserProfileEdit{} = entity, type, attrs) do
    changeset = UserProfileEdit.changeset(entity, type, attrs)

    socket
    |> save(changeset)
  end

  # data(entity, :any)
  # data(changeset, :any)
  # data(role_labels, :list)

  attr(:user, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Text.title2>User roles</Text.title2>
      <.form id="main_form" for={@changeset} phx-change="save" phx-target={@myself} >
        <.live_component
          module={Selector}
          id={:role_selector}
          items={@role_labels}
          type={:radio}
          parent={%{type: __MODULE__, id: @id}}
        />
      </.form>
      </Area.content>
    </div>
    """
  end
end
