defmodule Systems.Storage.EndpointDataView do
  use CoreWeb, :live_component

  alias Systems.Storage

  @impl true
  def update(
        %{endpoint: endpoint, files: files, context_name: context_name},
        %{assigns: %{}} = socket
      ) do
    {
      :ok,
      socket
      |> assign(
        endpoint: endpoint,
        files: files,
        show: 100,
        context_name: context_name
      )
      |> update_buttons()
    }
  end

  defp update_buttons(%{assigns: %{files: []}} = socket) do
    assign(socket, buttons: [])
  end

  defp update_buttons(%{assigns: %{endpoint: %{id: id}}} = socket) do
    export_button = %{
      action: %{
        type: :http_download,
        to: ~p"/storage/#{id}/export"
      },
      face: %{
        type: :label,
        label: dgettext("eyra-storage", "export.files.button"),
        icon: :export
      }
    }

    empty_button = %{
      action: %{
        type: :send,
        event: "empty"
      },
      face: %{
        type: :label,
        label: dgettext("eyra-storage", "empty.files.button"),
        icon: :delete,
        color: :red
      }
    }

    assign(socket, buttons: [export_button, empty_button])
  end

  @impl true
  def handle_event("empty", _payload, socket) do
    {
      :noreply,
      socket
      |> compose_child(:empty_confirmation)
      |> show_modal(:empty_confirmation, :notification)
    }
  end

  @impl true
  def handle_event("empty_confirmation", _payload, socket) do
    {
      :noreply,
      socket
      |> empty_storage()
      |> hide_modal(:empty_confirmation)
    }
  end

  @impl true
  def compose(:empty_confirmation, %{context_name: context_name}) do
    %{
      module: Storage.EmptyConfirmationView,
      params: %{
        context_name: context_name
      }
    }
  end

  defp empty_storage(%{assigns: %{endpoint: endpoint}} = socket) do
    Storage.Public.delete_files(endpoint)
    socket
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
          <Button.dynamic_bar buttons={@buttons}/>
        </div>
        <%= if not Enum.empty?(@files) do %>
          <.spacing value="L" />
          <Storage.Html.files_table files={@files |> Enum.take(@show)} />
        <% end %>
      </Area.content>
    </div>
    """
  end
end
