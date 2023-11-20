defmodule Systems.Storage.EndpointForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Frameworks.Concept
  alias Frameworks.Pixel.Selector

  alias Systems.{
    Storage
  }

  @special_form_key :storage_endpoint_special_form

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: special_type, selector_id: :special_type_selector},
        socket
      ) do
    special = Storage.Private.build_special(special_type)

    {
      :ok,
      socket
      |> assign(
        special_type: special_type,
        special_changeset: nil,
        special: special
      )
      |> update_special_form()
    }
  end

  # Handle initial update
  @impl true
  def update(
        %{id: id, endpoint: endpoint},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        endpoint: endpoint
      )
      |> update_special_type()
      |> update_type_selector()
      |> update_special()
      |> update_special_form()
    }
  end

  defp update_special_type(%{assigns: %{endpoint: endpoint}} = socket) do
    special_type = Storage.EndpointModel.special_field_id(endpoint)
    assign(socket, special_type: special_type)
  end

  defp update_type_selector(%{assigns: %{id: id, special_type: special_type}} = socket) do
    items = Storage.ServiceIds.labels(special_type, Storage.Private.allowed_service_ids())

    type_selector = %{
      module: Selector,
      id: :special_type_selector,
      grid_options: "flex flex-row gap-4",
      items: items,
      type: :radio,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, type_selector: type_selector)
  end

  defp update_special(%{assigns: %{endpoint: endpoint}} = socket) do
    special = Storage.EndpointModel.special(endpoint)
    assign(socket, special: special)
  end

  defp update_special_form(%{assigns: %{special_type: nil}} = socket) do
    socket
    |> assign(@special_form_key, nil)
    |> assign(special_form_title: nil)
  end

  defp update_special_form(%{assigns: %{special_type: special_type, special: special}} = socket) do
    special_form_title = Storage.ServiceIds.translate(special_type)

    child =
      prepare_child(socket, @special_form_key, Concept.ContentModel.form(special), %{
        model: special
      })

    socket
    |> replace_child(child)
    |> assign(special_form_title: special_form_title)
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
  def handle_event("update", %{source: %{id: @special_form_key}, changeset: changeset}, socket) do
    {
      :noreply,
      socket
      |> assign(special_changeset: changeset)
      |> update_changeset()
    }
  end

  @impl true
  def handle_event("show_errors", _payload, socket) do
    {:noreply, socket |> send_event(@special_form_key, "show_errors")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.form_field_label id={:type}><%= dgettext("eyra-storage", "endpoint_form.type.label") %></Text.form_field_label>
      <.spacing value="XS" />
      <div class="w-full">
        <.live_component {@type_selector} />
      </div>
      <%= if get_child(@fabric, :storage_endpoint_special_form) do %>
        <.spacing value="L" />
        <Text.title4><%= @special_form_title %> </Text.title4>
        <.spacing value="XS" />
        <.child id={:storage_endpoint_special_form} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
