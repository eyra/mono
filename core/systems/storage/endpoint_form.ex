defmodule Systems.Storage.EndpointForm do
  use CoreWeb.LiveForm

  alias Frameworks.Concept
  alias Frameworks.Pixel.Selector

  alias Systems.{
    Storage
  }

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: special_field, selector_id: :storage_type_selector},
        %{assigns: %{entity: endpoint}} = socket
      ) do
    special = Storage.Assembly.prepare_endpoint_special(special_field)

    changeset = Storage.EndpointModel.reset_special(endpoint, special_field, special)

    {
      :ok,
      socket
      |> save(changeset)
      |> update_selected_type()
      |> update_special()
      |> update_special_form()
    }
  end

  # Handle initial update
  @impl true
  def update(
        %{id: id, entity: endpoint},
        socket
      ) do
    changeset = Storage.EndpointModel.changeset(endpoint, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: endpoint,
        changeset: changeset
      )
      |> update_selected_type()
      |> update_type_selector()
      |> update_special()
      |> update_special_form()
    }
  end

  defp update_selected_type(%{assigns: %{entity: entity}} = socket) do
    selected_type = Storage.EndpointModel.special_field(entity)
    assign(socket, selected_type: selected_type)
  end

  defp update_type_selector(%{assigns: %{id: id, selected_type: selected_type}} = socket) do
    items = Storage.BackendTypes.labels(selected_type)

    type_selector = %{
      module: Selector,
      id: :storage_type_selector,
      grid_options: "grid gap-3 grid-cols-2",
      items: items,
      type: :radio,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, type_selector: type_selector)
  end

  defp update_special(%{assigns: %{entity: entity}} = socket) do
    special = Storage.EndpointModel.special(entity)
    assign(socket, special: special)
  end

  defp update_special_form(%{assigns: %{selected_type: nil}} = socket) do
    assign(socket, special_form: nil, special_form_title: nil)
  end

  defp update_special_form(%{assigns: %{special: special, selected_type: selected_type}} = socket) do
    special_form_title = Storage.BackendTypes.translate(selected_type)

    special_form = %{
      module: Concept.ContentModel.form(special),
      id: :storage_endpoint_special_form,
      entity: special
    }

    assign(socket, special_form: special_form, special_form_title: special_form_title)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.form_field_label id={:type}><%= dgettext("eyra-storage", "endpoint_form.type.label") %></Text.form_field_label>
      <.spacing value="XS" />
      <div class="w-[286px]">
        <.live_component {@type_selector} />
      </div>
      <.spacing value="L" />
      <%= if @special_form do %>
        <Text.title4><%= @special_form_title %> </Text.title4>
        <.spacing value="XS" />
        <.live_component {@special_form} />
      <% end %>
    </div>
    """
  end
end
