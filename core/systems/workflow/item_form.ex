defmodule Systems.Workflow.ItemForm do
  use CoreWeb.LiveForm

  import Frameworks.Pixel.Form

  alias Systems.{
    Workflow
  }

  @impl true
  def update(
        %{id: id, entity: entity, group_enabled?: group_enabled?},
        socket
      ) do
    changeset = Workflow.ItemModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset,
        group_enabled?: group_enabled?
      )
      |> update_group_options()
      |> update_selected_group()
    }
  end

  defp update_selected_group(%{assigns: %{entity: %{group: group}}} = socket) do
    assign(socket, selected_group: group)
  end

  defp update_group_options(socket) do
    group_options = Workflow.Platforms.labels()
    assign(socket, group_options: group_options)
  end

  # Handle Events
  @impl true
  def handle_event("select-option", %{"id" => group}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> assign(selected_group: group)
      |> save(entity, %{group: group})
    }
  end

  @impl true
  def handle_event("save", %{"item_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, %Workflow.ItemModel{} = entity, attrs) do
    changeset = Workflow.ItemModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <%= if @group_enabled? do %>
          <.dropdown
            form={form}
            field={:group}
            options={@group_options}
            label_text={dgettext("eyra-workflow", "item.group.label")}
            target={@myself}
          />
        <% end %>
        <.text_input form={form} field={:title} label_text={dgettext("eyra-workflow", "item.title.label")} />
        <.text_input form={form} field={:description} label_text={dgettext("eyra-workflow", "item.description.label")} />
      </.form>
    </div>
    """
  end
end
