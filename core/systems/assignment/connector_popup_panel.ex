defmodule Systems.Assignment.ConnectorPopupPanel do
  use CoreWeb, :live_component

  import CoreWeb.UI.Dialog
  alias Frameworks.Pixel.Annotation
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Panel

  alias Systems.{
    Assignment
  }

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity
      )
      |> update_title()
      |> update_text()
      |> update_buttons()
      |> update_selected_type()
      |> compose_child(:panel_type_selector)
      |> update_annotation()
    }
  end

  @impl true
  def compose(:panel_type_selector, %{selected_type: selected_type}) do
    items =
      Assignment.ExternalPanelIds.labels(
        selected_type,
        Assignment.Private.allowed_external_panel_ids()
      )

    %{
      module: Selector,
      params: %{
        grid_options: "flex flex-row gap-8",
        items: items,
        type: :radio
      }
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "connector.panel.title")
    assign(socket, title: title)
  end

  defp update_text(socket) do
    text = dgettext("eyra-assignment", "connector.panel.text")
    assign(socket, text: text)
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    buttons = [
      %{
        action: %{type: :send, target: myself, event: "connect"},
        face: %{type: :primary, label: dgettext("eyra-assignment", "connector.connect.button")}
      },
      %{
        action: %{type: :send, target: myself, event: "cancel"},
        face: %{type: :label, label: dgettext("eyra-assignment", "connector.cancel.button")}
      }
    ]

    assign(socket, buttons: buttons)
  end

  defp update_selected_type(%{assigns: %{entity: %{external_panel: external_panel}}} = socket) do
    assign(socket, selected_type: external_panel)
  end

  defp update_annotation(%{assigns: %{selected_type: nil}} = socket) do
    assign(socket, annotation: nil)
  end

  defp update_annotation(%{assigns: %{selected_type: selected_type}} = socket) do
    annotation =
      case selected_type do
        :liss -> dgettext("eyra-assignment", "panel.liss.connector.annotation")
        :ioresearch -> dgettext("eyra-assignment", "panel.ioresearch.connector.annotation")
        :generic -> dgettext("eyra-assignment", "panel.generic.connector.annotation")
      end

    annotation_title = Assignment.ExternalPanelIds.translate(selected_type)

    socket
    |> assign(annotation: annotation)
    |> assign(annotation_title: annotation_title)
  end

  @impl true
  def handle_event("connect", _payload, socket) do
    {
      :noreply,
      socket |> connect()
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
  def handle_event(
        "active_item_id",
        %{active_item_id: panel_type, selector_id: :panel_type_selector},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(selected_type: panel_type)
      |> update_annotation()
    }
  end

  defp connect(%{assigns: %{selected_type: nil}} = socket) do
    socket
  end

  defp connect(%{assigns: %{selected_type: panel_type, entity: entity}} = socket) do
    Assignment.Public.update(entity, %{external_panel: panel_type})
    socket |> send_event(:parent, "finish", %{connection: %{external_panel: panel_type}})
  end

  defp cancel_popup(socket) do
    socket |> send_event(:parent, "cancel")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog {%{title: @title, text: @text, buttons: @buttons}}>
        <Text.form_field_label id={:type}><%= dgettext("eyra-assignment", "panel_form.type.label") %></Text.form_field_label>
        <.spacing value="XS" />
        <div class="w-full">
          <.child name={:type_selector} fabric={@fabric} />
        </div>
        <%= if @annotation do %>
          <.spacing value="M" />
          <Panel.flat bg_color="bg-grey1">
            <:title>
              <div class="text-title5 font-title5 text-white">
                <%= @annotation_title %>
              </div>
            </:title>
            <.spacing value="XS" />
            <Annotation.view annotation={@annotation} />
          </Panel.flat>
        <% end %>
      </.dialog>
    </div>
    """
  end
end
