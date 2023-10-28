defmodule Systems.Assignment.SettingsView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector

  alias Systems.{
    Assignment,
    Storage
  }

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: active_item_id, selector_id: :enable_storage_selector},
        socket
      ) do
    {
      :ok,
      socket
      |> update_storage_endpoint(active_item_id)
      |> update_enable_storage_selector()
      |> update_storage_endpoint_form()
    }
  end

  @impl true
  def update(%{id: id, entity: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment
      )
      |> update_enable_storage_selector()
      |> update_storage_endpoint_form()
    }
  end

  def update_storage_endpoint(%{assigns: %{entity: assignment}} = socket, enabled) do
    assignment =
      if enabled == :no do
        Assignment.Public.delete_storage_endpoint!(assignment)
      else
        Assignment.Public.create_storage_endpoint!(assignment)
      end

    socket
    |> assign(entity: assignment)
    |> update_enable_storage_selector()
    |> update_storage_endpoint_form()
  end

  def update_enable_storage_selector(
        %{assigns: %{id: id, entity: %{storage_endpoint_id: storage_endpoint_id}}} = socket
      ) do
    enabled = storage_endpoint_id != nil

    labels = [
      %{id: :no, value: "No, disable", active: not enabled},
      %{id: :yes, value: "Yes, enable", active: enabled}
    ]

    enable_storage_selector = %{
      module: Selector,
      id: :enable_storage_selector,
      grid_options: "flex flex-row gap-8",
      items: labels,
      type: :radio,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, enable_storage_selector: enable_storage_selector)
  end

  def update_storage_endpoint_form(%{assigns: %{entity: %{storage_endpoint_id: nil}}} = socket) do
    assign(socket, storage_form: nil)
  end

  def update_storage_endpoint_form(
        %{assigns: %{entity: %{storage_endpoint: storage_endpoint}}} = socket
      ) do
    storage_form = %{
      id: :storage_endpoint_revision,
      module: Storage.EndpointForm,
      entity: storage_endpoint
    }

    assign(socket, storage_form: storage_form)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "settings.title") %></Text.title2>
        <Text.form_field_label id="assignment.settings.data_storage.title" ><%= dgettext("eyra-assignment", "settings.data_storage.title") %></Text.form_field_label>
        <.spacing value="XS" />
        <.live_component {@enable_storage_selector} />
        <%= if @storage_form do %>
          <.spacing value="M" />
          <.live_component {@storage_form} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
