defmodule Systems.Assignment.ConnectorPopupStorage do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import CoreWeb.UI.Dialog

  alias Systems.{
    Storage
  }

  @endpoint_form_key :endpoint_form

  @impl true
  def update(%{id: id, entity: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment
      )
      |> update_title()
      |> update_text()
      |> update_buttons()
      |> update_storage_endpoint()
      |> update_storage_endpoint_form()
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "connector.storage.title")
    assign(socket, title: title)
  end

  defp update_text(socket) do
    text = dgettext("eyra-assignment", "connector.storage.text")
    assign(socket, text: text)
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    buttons = [
      %{
        action: %{type: :send, target: myself, event: "connect_storage"},
        face: %{type: :primary, label: dgettext("eyra-assignment", "connector.connect.button")}
      },
      %{
        action: %{type: :send, target: myself, event: "cancel"},
        face: %{type: :label, label: dgettext("eyra-assignment", "connector.cancel.button")}
      }
    ]

    assign(socket, buttons: buttons)
  end

  def update_storage_endpoint(%{assigns: %{entity: %{storage_endpoint_id: nil}}} = socket) do
    assign(socket, storage_endpoint: %Storage.EndpointModel{})
  end

  def update_storage_endpoint(
        %{assigns: %{entity: %{storage_endpoint: storage_endpoint}}} = socket
      ) do
    assign(socket, storage_endpoint: storage_endpoint)
  end

  defp update_storage_endpoint_form(%{assigns: %{storage_endpoint: storage_endpoint}} = socket) do
    child =
      prepare_child(socket, @endpoint_form_key, Storage.EndpointForm, %{
        endpoint: storage_endpoint
      })

    show_child(socket, child)
  end

  @impl true
  def handle_event("connect_storage", _payload, socket) do
    {
      :noreply,
      socket |> commit_form()
    }
  end

  @impl true
  def handle_event("cancel", _payload, socket) do
    {
      :noreply,
      socket |> cancel_popup()
    }
  end

  @impl true
  def handle_event("update", %{source: %{id: @endpoint_form_key}, changeset: changeset}, socket) do
    {
      :noreply,
      socket |> assign(endpoint_changeset: changeset)
    }
  end

  defp commit_form(%{assigns: %{endpoint_changeset: nil}} = socket) do
    socket
  end

  defp commit_form(%{assigns: %{endpoint_changeset: endpoint_changeset}} = socket) do
    case Ecto.Changeset.apply_action(endpoint_changeset, :update) do
      {:ok, endpoint} ->
        socket
        |> assign(endpoint: endpoint)
        |> finish()

      {:error, _} ->
        socket
        |> send_event(@endpoint_form_key, "show_errors")
    end
  end

  defp cancel_popup(socket) do
    socket |> send_event(:parent, "cancel")
  end

  defp finish(%{assigns: %{endpoint: endpoint}} = socket) do
    socket |> send_event(:parent, "finish", %{connection: endpoint})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog {%{title: @title, text: @text, buttons: @buttons}}>
        <.child id={:endpoint_form} fabric={@fabric}/>
      </.dialog>
    </div>
    """
  end
end
