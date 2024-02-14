defmodule Systems.Storage.EndpointForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Frameworks.Concept
  alias Frameworks.Pixel.RadioGroup
  alias Frameworks.Pixel.Annotation
  alias Frameworks.Pixel.Panel

  alias Systems.{
    Storage
  }

  @impl true
  def update(
        %{id: id, endpoint: endpoint, key: key},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        endpoint: endpoint,
        key: key
      )
      |> update_special_type()
      |> update_special()
      |> update_special_annotation()
      |> compose_child(:type_selector)
      |> compose_child(:special_form)
    }
  end

  defp update_special_type(%{assigns: %{endpoint: endpoint}} = socket) do
    special_type = Storage.EndpointModel.special_field(endpoint)
    assign(socket, special_type: special_type)
  end

  defp update_special(%{assigns: %{endpoint: endpoint}} = socket) do
    special = Storage.EndpointModel.special(endpoint)
    assign(socket, special: special)
  end

  defp update_special_annotation(%{assigns: %{special_type: nil}} = socket) do
    assign(socket, annotation: nil)
  end

  defp update_special_annotation(%{assigns: %{special_type: special_type}} = socket) do
    annotation =
      case special_type do
        :builtin -> dgettext("eyra-storage", "builtin.annotation")
        :yoda -> dgettext("eyra-storage", "yoda.annotation")
        :centerdata -> dgettext("eyra-storage", "centerdata.annotation")
        :aws -> dgettext("eyra-storage", "aws.annotation")
        :azure -> dgettext("eyra-storage", "azure.annotation")
      end

    annotation_title = Storage.ServiceIds.translate(special_type)

    socket
    |> assign(annotation: annotation)
    |> assign(annotation_title: annotation_title)
  end

  @impl true
  def compose(:type_selector, %{special_type: special_type}) do
    items = Storage.ServiceIds.labels(special_type, Storage.Private.allowed_service_ids())

    %{
      module: RadioGroup,
      params: %{
        items: items
      }
    }
  end

  @impl true
  def compose(:special_form, %{special: nil}) do
    nil
  end

  @impl true
  def compose(:special_form, %{special: special, key: key}) do
    %{
      module: Concept.ContentModel.form(special),
      params: %{
        model: special,
        key: key
      }
    }
  end

  defp update_changeset(%{assigns: %{special_changeset: nil}} = socket) do
    socket
  end

  defp update_changeset(
         %{
           assigns: %{
             endpoint: endpoint,
             special_type: special_type,
             special_changeset: special_changeset
           }
         } = socket
       ) do
    changeset = Storage.EndpointModel.reset_special(endpoint, special_type, special_changeset)

    socket
    |> send_event(:parent, "update", %{changeset: changeset})
  end

  @impl true
  def handle_event("update", %{source: %{name: :type_selector}, status: special_type}, socket) do
    special = Storage.Private.build_special(special_type)

    {
      :noreply,
      socket
      |> assign(
        special_type: special_type,
        special_changeset: nil,
        special: special
      )
      |> update_special_annotation()
      |> compose_child(:type_selector)
      |> compose_child(:special_form)
    }
  end

  @impl true
  def handle_event("update", %{source: %{name: :special_form}, changeset: changeset}, socket) do
    {
      :noreply,
      socket
      |> assign(special_changeset: changeset)
      |> update_changeset()
    }
  end

  @impl true
  def handle_event("show_errors", _payload, socket) do
    {:noreply, socket |> send_event(:special_form, "show_errors")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.form_field_label id={:type}><%= dgettext("eyra-storage", "endpoint_form.type.label") %></Text.form_field_label>
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
      <%= if get_child(@fabric, :special_form) do %>
        <.spacing value="M" />
        <.child name={:special_form} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
