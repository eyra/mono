defmodule CoreWeb.User.Forms.Debug do
  use CoreWeb.LiveForm

  alias Core.Accounts
  alias Core.Accounts.UserProfileEdit

  alias EyraUI.Text.{Title2}
  alias EyraUI.Form.{Form, Checkbox}

  prop(user, :any, required: true)

  data(entity, :any)
  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, user: user}, socket) do
    profile = Accounts.get_profile(user)
    entity = UserProfileEdit.create(user, profile)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
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
  def handle_event("toggle", %{"checkbox" => checkbox}, %{assigns: %{entity: entity}} = socket) do
    new_value = not Map.get(entity, checkbox, false)
    attrs = %{checkbox => new_value}

    {
      :noreply,
      socket
      |> force_save(entity, :auto_save, attrs)
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
            <Checkbox field={{:student}} label_text="Student" />
            <Checkbox field={{:researcher}} label_text="Researcher" />
            <Checkbox field={{:coordinator}} label_text="Coordinator" />
          </Form>
        </ContentArea>
    """
  end
end
