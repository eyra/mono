defmodule Systems.Storage.EndpointFilesView do
  use CoreWeb, :live_component

  alias CoreWeb.UI.Timestamp
  alias Systems.Storage

  @max 100

  @impl true
  def update(%{endpoint: endpoint, query: query, timezone: timezone}, socket) do
    filtered_files = Map.get(socket.assigns, :filtered_files, [])

    {
      :ok,
      socket
      |> assign(
        endpoint: endpoint,
        query: query,
        timezone: timezone,
        filtered_files: filtered_files
      )
    }
  end

  @impl true
  def handle_event(
        "start_loading",
        _payload,
        %{assigns: %{endpoint: endpoint, timezone: timezone}} = socket
      ) do
    files =
      endpoint
      |> Storage.Public.list_files()
      |> Enum.sort(&Timestamp.after?(&1.timestamp, &2.timestamp))
      |> Enum.map(fn %{timestamp: timestamp} = file ->
        %{file | timestamp: Timestamp.convert(timestamp, timezone)}
      end)

    {
      :noreply,
      socket
      |> assign(files: files)
      |> update_filtered_files()
    }
  end

  @impl true
  def handle_event("handle_query", %{query: query}, socket) do
    {
      :noreply,
      socket
      |> assign(query: query)
      |> update_filtered_files()
    }
  end

  defp update_filtered_files(%{assigns: %{files: files, query: query}} = socket) do
    filtered_files =
      Enum.reduce(files, [], fn file, acc ->
        if Enum.count(acc) < @max and include(file, query) do
          acc ++ [file]
        else
          acc
        end
      end)

    socket
    |> send_event(:parent, "files", %{
      visible_count: Enum.count(filtered_files),
      total_count: Enum.count(files)
    })
    |> assign(filtered_files: filtered_files)
  end

  defp include(file, [hd | tl]), do: include(file, hd) and include(file, tl)
  defp include(%{path: path}, word) when is_binary(word), do: String.contains?(path, word)
  defp include(_, _), do: true

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <%= if not Enum.empty?(@filtered_files) do %>
          <Storage.Html.files_table files={@filtered_files} />
        <% end %>
      </div>
    """
  end
end
