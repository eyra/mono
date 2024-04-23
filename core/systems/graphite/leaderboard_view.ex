defmodule Systems.Graphite.LeaderboardTableView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Align

  alias Systems.{
    Graphite
  }

  import Graphite.LeaderboardScoreHTML

  @impl true
  def update(
        %{
          active_item_id: active_item_id,
          selector_id: :metric_selector
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(active_metric: active_item_id)
      |> update_scores()
    }
  end

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
      |> update_scores()
      |> update_selector()
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

  defp update_selector(
         %{assigns: %{id: id, metrics: metrics, active_metric: active_metric}} = socket
       ) do
    metric_items = Enum.map(metrics, &to_selector_item(&1, active_metric))

    selector = %{
      id: :metric_selector,
      module: Selector,
      items: metric_items,
      type: :segmented,
      parent: %{type: __MODULE__, id: id}
    }

    assign(socket, selector: selector)
  end

  defp to_selector_item(metric, active_metric) do
    %{
      id: metric,
      value: String.capitalize(String.replace(metric, "_", " ")),
      active: metric == active_metric
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Align.horizontal_center>
        <.live_component {@selector} />
      </Align.horizontal_center>
      <.spacing value="M" />
      <%= if @active_metric do %>
        <.table scores={@scores} />
      <% end %>
    </div>
    """
  end
end
