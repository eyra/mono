defmodule Systems.Storage.EndpointDataView do
  use CoreWeb, :live_component

  alias Systems.Storage.Html

  @impl true
  def update(%{endpoint: endpoint, files: files}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(
        endpoint: endpoint,
        files: files
      )
      |> update_export_button()
    }
  end

  def update_export_button(%{assigns: %{endpoint: %{id: id}}} = socket) do
    export_button = %{
      action: %{
        type: :http_get,
        to: ~p"/storage/#{id}/export",
        target: "_blank"
      },
      face: %{
        type: :label,
        label: dgettext("eyra-storage", "export.files.button"),
        icon: :export
      }
    }

    assign(socket, export_button: export_button)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-center">
          <Text.title2 margin=""><%= dgettext("eyra-storage", "tabbar.item.data") %> <span class="text-primary"><%= Enum.count(@files) %></span></Text.title2>
          <div class="flex-grow" />
          <div>
            <Button.dynamic {@export_button} />
          </div>
        </div>
        <%= if not Enum.empty?(@files) do %>
          <.spacing value="L" />
          <Html.files_table files={@files} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
