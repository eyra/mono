defmodule Systems.DataDonation.ToolForm do
  use CoreWeb.LiveForm

  alias Core.Accounts

  import Frameworks.Pixel.Form

  alias Systems.{
    DataDonation
  }

  @impl true
  def update(
        %{id: id, entity_id: entity_id},
        socket
      ) do
    entity = DataDonation.Public.get_tool!(entity_id)
    changeset = DataDonation.ToolModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        entity: entity,
        changeset: changeset
      )
    }
  end

  # Handle Events

  @impl true
  def handle_event("save", %{"tool_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{entity_id: entity_id, current_user: user}} = socket
      ) do
    DataDonation.Public.get_tool!(entity_id)
    |> DataDonation.Public.delete()

    {:noreply, push_redirect(socket, to: Accounts.start_page_path(user))}
  end

  # Saving
  def save(socket, %DataDonation.ToolModel{} = entity, attrs) do
    changeset = DataDonation.ToolModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.number_input form={form} field={:subject_count} label_text={dgettext("eyra-data-donation", "config.nrofsubjects.label")} />
      </.form>
    </div>
    """
  end
end
