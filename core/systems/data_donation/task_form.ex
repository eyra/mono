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
      |> update_platform_options()
      |> update_selected_platform()
    }
  end

  defp update_selected_platform(%{assigns: %{entity: %{platform: platform}}} = socket) do
    assign(socket, selected_platform: platform)
  end

  defp update_platform_options(socket) do
    platform_options = DataDonation.Platforms.labels()
    assign(socket, platform_options: platform_options)
  end

  # Handle Events
  @impl true
  def handle_event("select-option", %{"id" => platform}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> assign(selected_platform: platform)
      |> save(entity, %{platform: platform})
    }
  end

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
    changeset = DataDonation.TaskModel.changeset(entity, attrs) |> dbg()

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.dropdown
          form={form}
          field={:platform}
          options={@platform_options}
          label_text={dgettext("eyra-data-donation", "task.platform.label")}
          target={@myself}
        />
        <.text_input form={form} field={:title} label_text={dgettext("eyra-data-donation", "task.title.label")} />
        <.text_input form={form} field={:description} label_text={dgettext("eyra-data-donation", "task.description.label")} />
      </.form>
    </div>
    """
  end
end
