defmodule Systems.Storage.EndpointDataView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.SearchBar
  alias Systems.Storage

  @impl true
  def update(
        %{endpoint: endpoint, branch_name: branch_name, timezone: timezone},
        %{assigns: %{}} = socket
      ) do
    total_count = Map.get(socket.assigns, :total_count, nil)
    visible_count = Map.get(socket.assigns, :visible_count, nil)
    query = Map.get(socket.assigns, :query, nil)
    query_string = Map.get(socket.assigns, :query_string, nil)

    {
      :ok,
      socket
      |> assign(
        endpoint: endpoint,
        branch_name: branch_name,
        timezone: timezone,
        total_count: total_count,
        visible_count: visible_count,
        query: query,
        query_string: query_string
      )
      |> update_buttons()
      |> compose_child(:search_bar)
      |> compose_child(:files_view)
      |> send_event(:files_view, "start_loading")
    }
  end

  @impl true
  def compose(:files_view, %{endpoint: endpoint, query: query, timezone: timezone}) do
    %{
      module: Storage.EndpointFilesView,
      params: %{
        endpoint: endpoint,
        query: query,
        timezone: timezone
      }
    }
  end

  def compose(:empty_confirmation, %{branch_name: branch_name}) do
    %{
      module: Storage.EmptyConfirmationView,
      params: %{
        branch_name: branch_name
      }
    }
  end

  @impl true
  def compose(:search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-storage", "search.placeholder"),
        debounce: "200"
      }
    }
  end

  defp update_buttons(%{assigns: %{files: []}} = socket) do
    assign(socket, buttons: [])
  end

  defp update_buttons(%{assigns: %{endpoint: %{id: id}}} = socket) do
    export_button = %{
      action: %{
        type: :http_download,
        to: ~p"/storage/endpoint/#{id}/export"
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
      |> send_event(:files_view, "start_loading")
    }
  end

  @impl true
  def handle_event("files", %{visible_count: visible_count, total_count: total_count}, socket) do
    {:noreply, socket |> assign(visible_count: visible_count, total_count: total_count)}
  end

  @impl true
  def handle_event("update_files", _payload, socket) do
    {:noreply, socket |> send_event(:files_view, "start_loading")}
  end

  @impl true
  def handle_event("search_query", %{query: query, query_string: query_string}, socket) do
    {
      :noreply,
      socket
      |> assign(query: query, query_string: query_string)
      |> send_event(:files_view, "handle_query", %{query: query, query_string: query_string})
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
        <div class="flex flex-row items-center gap-3">
          <Text.title2 margin=""><%= dgettext("eyra-storage", "tabbar.item.data") %></Text.title2>
          <%= if @total_count do %>
            <Text.title2 margin=""><span class="text-primary"><%= @total_count %></span></Text.title2>
            <%= if @total_count > 0 do %>
              <div class="flex-grow" />
              <Button.dynamic_bar buttons={@buttons}/>
            <% end %>
          <% else %>
            <div class="w-8 h-8 animate-spin">
              <img src={~p"/images/icons/loading_primary@3x.png"} alt={"Loading"}>
            </div>
          <% end %>
        </div>
        <%= if @total_count do %>
          <.spacing value="M" />
          <%= if @total_count > 0 do %>
            <Text.body_large><%= dgettext("eyra-storage", "files.description") %></Text.body_large>
            <.spacing value="M" />
            <div class="flex flex-row items-center">
              <Text.title3><%= dgettext("eyra-storage", "files.finder.title") %></Text.title3>
              <div class="flex-grow" />
              <%= if is_nil(@query_string) or @query_string == "" do %>
                <Text.caption><%= dgettext("eyra-storage", "files.recent.label", recent: @visible_count, total: @total_count) %></Text.caption>
              <% else %>
                <Text.caption><%= dgettext("eyra-storage", "files.search.label", result: @visible_count, total: @total_count) %></Text.caption>
              <% end %>
              <.child name={:search_bar} fabric={@fabric} />
            </div>
            <.spacing value="S" />
          <% else %>
            <Text.body_large><%= dgettext("eyra-storage", "files.empty.description") %></Text.body_large>
          <% end %>
        <% end %>
        <.child name={:files_view} fabric={@fabric} />
      </Area.content>
    </div>
    """
  end
end
