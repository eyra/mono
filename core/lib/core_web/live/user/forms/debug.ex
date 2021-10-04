defmodule CoreWeb.User.Forms.Debug do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Text.{Title2}
  alias EyraUI.Form.{Form}
  alias EyraUI.Selector.Selector

  prop(user, :any, required: true)

  data(entity, :any)
  data(changeset, :any)
  data(role_labels, :list)
  data(focus, :any, default: "")

  # Handle Selector Update
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
      |> force_save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

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

  def handle_event("toggle", %{"checkbox" => checkbox}, %{assigns: %{entity: entity}} = socket) do
    field = String.to_atom(checkbox)
    new_value = not Map.get(entity, field, false)
    attrs = %{field => new_value}

    {
      :noreply,
      socket
      |> force_save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  def handle_event(
        "save",
        %{"user_profile_edit" => attrs},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> schedule_save(entity, :auto_save, attrs)
      |> update_ui()
    }
  end

  def force_save(socket, entity, type, attrs), do: save(socket, entity, type, attrs, false)
  def schedule_save(socket, entity, type, attrs), do: save(socket, entity, type, attrs, true)

  def save(socket, %Core.Accounts.UserProfileEdit{} = entity, type, attrs, schedule?) do
    changeset = UserProfileEdit.changeset(entity, type, attrs)

    socket
    |> save(changeset, schedule?)
  end

  @impl true
  def render(assigns) do
    ~H"""
        <ContentArea>
          <Title2>User roles</Title2>
          <Form id="main_form" changeset={{@changeset}} change_event="save" target={{@myself}} focus={{@focus}}>
            <Selector id={{:role_selector}} items={{ @role_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
          </Form>
        </ContentArea>
    """
  end
end
