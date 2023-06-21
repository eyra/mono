defmodule Systems.Benchmark.LeaderboardOverview do
  use CoreWeb, :live_component

  @impl true
  def update(%{id: id, entity: %{id: tool_id}}, socket) do
    export_button = %{
      action: %{
        type: :http_get,
        to: ~p"/benchmark/#{tool_id}/export/submissions",
        target: "_blank"
      },
      face: %{type: :primary, label: "Export submissions"}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        export_button: export_button
      )
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <.wrap>
          <Button.dynamic {@export_button} />
        </.wrap>
      </Area.content>
    </div>
    """
  end
end
