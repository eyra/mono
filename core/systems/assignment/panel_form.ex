defmodule Systems.Assignment.PanelForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector

  alias Systems.{
    Assignment
  }

  # Handle Selector Update
  @impl true
  def update(
        %{active_item_id: panel_id, selector_id: :panel_selector},
        %{assigns: %{entity: assignment}} = socket
      ) do
    changeset = Assignment.Model.changeset(assignment, %{external_panel: panel_id})

    {
      :ok,
      socket
      |> save(changeset)
      |> update_panel_selector()
      |> update_panel_view()
    }
  end

  @impl true
  def update(%{id: id, uri_origin: uri_origin, entity: entity}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        uri_origin: uri_origin,
        entity: entity
      )
      |> update_panel_selector()
      |> update_panel_view()
    }
  end

  defp update_panel_selector(
         %{assigns: %{id: id, entity: %{external_panel: external_panel}}} = socket
       ) do
    items =
      Assignment.ExternalPanelIds.labels(
        external_panel,
        Assignment.Private.allowed_external_panel_ids()
      )

    panel_selector = %{
      module: Selector,
      id: :panel_selector,
      grid_options: "flex flex-col gap-3",
      items: items,
      type: :radio,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, panel_selector: panel_selector)
  end

  defp update_panel_view(%{assigns: %{entity: %{external_panel: nil}}} = socket) do
    assign(socket, panel_view: nil)
  end

  defp update_panel_view(%{assigns: %{entity: assignment, uri_origin: uri_origin}} = socket) do
    panel_view =
      if function = Assignment.Private.panel_function_component(assignment) do
        %{
          function: function,
          props: %{
            assignment: assignment,
            uri_origin: uri_origin
          }
        }
      else
        nil
      end

    assign(socket, panel_view: panel_view)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "panel.title")  %></Text.title2>
        <Text.form_field_label id={:type}><%= dgettext("eyra-assignment", "panel.label") %></Text.form_field_label>
        <.spacing value="XS" />
        <div class="w-[512px]">
          <.live_component {@panel_selector} />
        </div>
        <%= if @panel_view do %>
          <.spacing value="XS" />
         <.function_component {@panel_view} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
