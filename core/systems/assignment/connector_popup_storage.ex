defmodule Systems.Assignment.ConnectorPopupStorage do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import CoreWeb.UI.Dialog

  alias Systems.{
    Assignment,
    Storage
  }

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
      |> compose_child(:storage_endpoint_form)
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

  @impl true
  def compose(:storage_endpoint_form, %{storage_endpoint: storage_endpoint}) do
    %{
      module: Storage.EndpointForm,
      params: %{
        endpoint: storage_endpoint
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{source: %{name: :storage_endpoint_form}, changeset: changeset},
        socket
      ) do
    {
      :noreply,
      socket |> assign(endpoint_changeset: changeset)
    }
  end

  @impl true
  def handle_event("connect_storage", _payload, socket) do
    {:noreply, socket |> connect()}
  end

  @impl true
  def handle_event("cancel", _payload, socket) do
    {:noreply, socket |> cancel_popup()}
  end

  defp cancel_popup(socket) do
    socket |> send_event(:parent, "cancel")
  end

  defp connect(%{assigns: %{endpoint_changeset: nil}} = socket) do
    socket
  end

  defp connect(%{assigns: %{endpoint_changeset: endpoint_changeset, entity: entity}} = socket) do
    case Assignment.Public.update_storage_endpoint(entity, endpoint_changeset) do
      {:ok, assignment} ->
        socket
        |> assign(entity: assignment)
        |> send_event(:parent, "finish", %{connection: %{endpoint: assignment.storage_endpoint}})

      {:error, _changeset} ->
        socket
        |> send_event(:storage_endpoint_form, "show_errors")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog {%{title: @title, text: @text, buttons: @buttons}}>
        <.child name={:storage_endpoint_form} fabric={@fabric}/>
      </.dialog>
    </div>
    """
  end
end
