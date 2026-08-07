defmodule Systems.Project.ItemMonitorView do
  use CoreWeb, :live_component_fabric

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-project", "monitor.title")  %></Text.title2>
      </Area.content>
    </div>
    """
  end
end
