defmodule CoreWeb.User.Forms.Debug do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Selector

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
    |> compose_child(:role_selector)
  end

  @impl true
  def compose(:role_selector, %{role_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio
      }
    }
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, source: %{name: :role_selector}},
        %{assigns: %{entity: entity}} = socket
      ) do
    attrs =
      [:student, :researcher]
      |> Enum.reduce(%{}, fn field, acc ->
        Map.put(acc, field, field == active_item_id)
      end)

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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Text.title2>User roles</Text.title2>
      <.form id="main_form" for={@changeset} phx-change="save" phx-target={@myself} >
        <.child name={:selector} fabric={@fabric} />
      </.form>
      </Area.content>
    </div>
    """
  end
end
