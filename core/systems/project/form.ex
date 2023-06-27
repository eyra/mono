defmodule Systems.Project.Form do
  use CoreWeb.LiveForm

  alias Systems.{
    Project
  }

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: project, target: target},
        socket
      ) do
    changeset = Project.Model.changeset(project, %{})

    close_button = %{
      action: %{type: :send, event: "close"},
      face: %{type: :icon, icon: :close}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: project,
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
  def handle_event("save", %{"model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  # Saving

  def save(socket, %{root: root} = entity, attrs) do
    project_changeset = Project.Model.changeset(entity, attrs)
    root_changeset = Project.NodeModel.changeset(root, attrs)

    socket
    |> save(root_changeset)
    |> save(project_changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row">
          <div>
            <Text.title3><%= dgettext("eyra-project", "form.title")  %></Text.title3>
          </div>
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
      </div>

      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:name} label_text={dgettext("eyra-project", "form.name.label")} />
      </.form>
    </div>
    """
  end
end
