defmodule Systems.Zircon.Screening.ToolView do
  use CoreWeb, :live_component

  def update(%{tool: tool}, socket) do
    {:ok, assign(socket, tool: tool)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <%= for tool <- @tool do %>
        <div><%= tool.name %></div>
      <% end %>
    </div>
    """
  end
end
