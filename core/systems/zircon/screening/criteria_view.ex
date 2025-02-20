defmodule Systems.Zircon.CriteriaView do
  use CoreWeb, :live_component

  @impl true
  def update(%{tool: tool, title: title, content_flags: content_flags}, socket) do
    {
      :ok,
      socket
      |> assign(tool: tool, title: title, content_flags: content_flags)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= @title %></Text.title2>
        </Area.content>
      </div>
    """
  end
end
