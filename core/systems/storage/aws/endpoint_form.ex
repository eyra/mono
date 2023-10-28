defmodule Systems.Storage.AWS.EndpointForm do
  use CoreWeb.LiveForm

  alias Systems.Storage.AWS.EndpointModel

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
      <.form id={"#{@id}_aws_endpoint_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.text_input form={form} field={:access_key_id} label_text={dgettext("eyra-storage", "aws.access_key_id.label")} />
        <.password_input form={form} field={:secret_access_key} label_text={dgettext("eyra-storage", "aws.secret_access_key.label")} />
        <.text_input form={form} field={:s3_bucket_name} label_text={dgettext("eyra-storage", "aws.s3_bucket_name.label")} />
        <.text_input form={form} field={:region_code} label_text={dgettext("eyra-storage", "aws.region_code.label")} />
      </.form>
    </div>
    """
  end
end
