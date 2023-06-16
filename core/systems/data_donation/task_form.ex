defmodule Systems.DataDonation.TaskForm do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form

  alias Systems.{
    DataDonation
  }

  @impl true
  def update(
        %{id: id, entity_id: entity_id},
        socket
      ) do
    entity = DataDonation.Public.get_task!(entity_id)
    changeset = DataDonation.TaskModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset
      )
    }
  end

  # Handle Events

  @impl true
  def handle_event("save", %{"task_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, %DataDonation.TaskModel{} = entity, attrs) do
    changeset = DataDonation.TaskModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:title} label_text={dgettext("eyra-data-donation", "task.title.label")} />
        <.text_input form={form} field={:description} label_text={dgettext("eyra-data-donation", "task.description.label")} />
      </.form>
    </div>
    """
  end
end
