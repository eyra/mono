defmodule Systems.Graphite.LeaderboardTableView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Align

  alias Systems.Graphite

  import Graphite.LeaderboardScoreHTML

  @impl true
  def update(%{id: id, metrics: metrics, metric_scores: metric_scores}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        metrics: metrics,
        metric_scores: metric_scores
      )
      |> update_active_metric()
      |> compose_child(:metric_selector)
      |> update_scores()
    }
  end

  @impl true
  def compose(:metric_selector, %{metrics: metrics, active_metric: active_metric}) do
    items = Enum.map(metrics, &to_selector_item(&1, active_metric))

    %{
      module: Selector,
      params: %{
        items: items,
        type: :segmented
      }
    }
  end

  defp update_active_metric(%{assigns: %{metrics: [first_metric | _]}} = socket) do
    assign(socket, active_metric: first_metric)
  end

  defp update_active_metric(%{assigns: %{metrics: []}} = socket) do
    assign(socket, active_metric: nil)
  end

  defp update_scores(%{assigns: %{active_metric: nil}} = socket) do
    assign(socket, scores: [])
  end

  defp update_scores(
         %{assigns: %{active_metric: active_metric, metric_scores: metric_scores}} = socket
       ) do
    assign(socket, scores: Map.get(metric_scores, active_metric, []))
  end

  defp to_selector_item(metric, active_metric) do
    %{
      id: metric,
      value: String.capitalize(String.replace(metric, "_", " ")),
      active: metric == active_metric
    }
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, source: %{name: :metric_selector}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_metric: active_item_id)
      |> update_scores()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Align.horizontal_center>
        <.child name={:metric_selector} fabric={@fabric} />
      </Align.horizontal_center>
      <.spacing value="M" />
      <%= if @active_metric do %>
        <.table scores={@scores} />
      <% end %>
    </div>
    """
  end
end
