defmodule Systems.Zircon.Screening.PaperSetView do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view
  use Gettext, backend: CoreWeb.Gettext
  use Systems.Observatory.LiveFeature
  use CoreWeb.UI

  import Systems.Zircon.HTML, only: [paper_set_table: 1]
  import Frameworks.Pixel.Paginator, only: [paginator: 1]

  require Logger

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
  on_mount({Systems.Observatory.LiveHook, __MODULE__})

  alias Frameworks.Pixel.Text
  alias Systems.Paper

  def get_model(:not_mounted_at_router, %{"paper_set_id" => paper_set_id}, _socket) do
    Paper.Public.get_paper_set!(paper_set_id, Paper.SetModel.preload_graph(:down))
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
    }
  end

  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("select_page", %{"item" => page}, socket) do
    {
      :noreply,
      socket
      |> assign(page_index: String.to_integer(page))
      |> update_view_model()
    }
  end

  def handle_event("delete", %{"item" => paper_id}, socket) do
    paper_id = String.to_integer(paper_id)
    paper_set_id = socket.assigns.model.id

    # Delete the paper from the paper set
    Paper.Public.remove_paper_from_set!(paper_set_id, paper_id)

    # Reload the model to get updated paper list
    updated_model = Paper.Public.get_paper_set!(paper_set_id, Paper.SetModel.preload_graph(:down))

    {
      :noreply,
      socket
      |> assign(model: updated_model)
      |> update_view_model()
    }
  end

  @impl true
  def consume_event(
        %{name: "search_query", payload: %{query: query, query_string: query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(page_index: 0, query: query, query_string: query_string)
      |> update_view_model()
    }
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @vm.show_action_bar? do %>
        <.action_bar vm={@vm} socket={@socket} />
        <.spacing value="S" />
      <% end %>
      <.paper_set_table items={@vm.page} />
    </div>
    """
  end

  # Private function components

  defp action_bar(assigns) do
    ~H"""
    <div class="flex flex-row items-center">
      <.paginator active_page={@vm.page_index} page_count={@vm.page_count} />
      <div class="flex-grow" />
      <Text.caption>
          <%= @vm.page_count %> pages
      </Text.caption>
      <LiveNest.HTML.element {Map.from_struct(@vm.search_bar)} socket={@socket} />
    </div>
    """
  end
end
