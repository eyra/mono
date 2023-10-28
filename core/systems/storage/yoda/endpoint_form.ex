defmodule Systems.Storage.Yoda.EndpointForm do
  use CoreWeb.LiveForm

  alias Systems.Storage.Yoda.EndpointModel

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: endpoint},
        socket
      ) do
    changeset = EndpointModel.changeset(endpoint, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: endpoint,
        changeset: changeset
      )
    }
  end

  # Handle Events
  @impl true
  def handle_event("save", %{"endpoint_model" => attrs}, socket) do
    {
      :noreply,
      socket
      |> save_entity(attrs)
    }
  end

  # Saving
  def save_entity(%{assigns: %{entity: entity}} = socket, attrs) do
    changeset = EndpointModel.changeset(entity, attrs)

    socket
    |> save(changeset)
    |> validate(changeset)
  end

  def validate(socket, changeset) do
    changeset = EndpointModel.validate(changeset)

    socket
    |> assign(changeset: changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"#{@id}_yoda_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:url} label_text={dgettext("eyra-storage", "yoda.url.label")} />
        <.text_input form={form} field={:user} label_text={dgettext("eyra-storage", "yoda.user.label")} />
        <.password_input form={form} field={:password} label_text={dgettext("eyra-storage", "yoda.password.label")} />
      </.form>
    </div>
    """
  end
end
