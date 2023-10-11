defmodule Systems.Project.ItemForm do
  use CoreWeb.LiveForm

  alias Systems.{
    Project
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: item, target: target},
        socket
      ) do
    changeset = Project.ItemModel.changeset(item, %{})

    close_button = %{
      action: %{type: :send, event: "close"},
      face: %{type: :icon, icon: :close}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: item,
        target: target,
        close_button: close_button,
        changeset: changeset
      )
    }
  end

  # Handle Events
  @impl true
  def handle_event("close", _params, socket) do
    send(self(), %{module: __MODULE__, action: :close})
    {:noreply, socket}
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

  def save(socket, entity, attrs) do
    changeset = Project.ItemModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row">
          <div>
            <Text.title3><%= dgettext("eyra-project", "item.form.title")  %></Text.title3>
          </div>
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
      </div>

      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "item.form.name.label")} />
      </.form>
    </div>
    """
  end
end
