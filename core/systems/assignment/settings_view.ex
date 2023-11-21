defmodule Systems.Assignment.SettingsView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.{
    Assignment
  }

  @impl true
  def update(%{id: id, entity: assignment, uri_origin: uri_origin}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment,
        uri_origin: uri_origin
      )
      |> compose_child(:consent)
      |> compose_child(:panel_connector)
      |> compose_child(:storage_connector)
    }
  end

  @impl true
  def compose(:consent, %{entity: assignment}) do
    %{
      module: Assignment.GdprForm,
      params: %{
        entity: assignment
      }
    }
  end

  @impl true
  def compose(:panel_connector, %{entity: assignment, uri_origin: uri_origin}) do
    %{
      module: Assignment.ConnectorView,
      params: %{
        assignment: assignment,
        connection: assignment.external_panel,
        type: :panel,
        uri_origin: uri_origin
      }
    }
  end

  @impl true
  def compose(:storage_connector, %{entity: assignment, uri_origin: uri_origin}) do
    %{
      module: Assignment.ConnectorView,
      params: %{
        assignment: assignment,
        connection: assignment.storage_endpoint,
        type: :storage,
        uri_origin: uri_origin
      }
    }
  end

  @impl true
  def handle_event("finish", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "settings.title") %></Text.title2>
        <.spacing value="L" />

        <.child id={:consent} fabric={@fabric} >
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.consent.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.consent.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child id={:panel_connector} fabric={@fabric}>
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.panel.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.panel.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

        <.child id={:storage_connector} fabric={@fabric}>
          <:header>
            <Text.title3><%= dgettext("eyra-assignment", "settings.data_storage.title") %></Text.title3>
            <Text.body><%= dgettext("eyra-assignment", "settings.data_storage.body") %></Text.body>
            <.spacing value="M" />
          </:header>
          <:footer>
            <.spacing value="L" />
          </:footer>
        </.child>

      </Area.content>
    </div>
    """
  end
end
