defmodule Systems.Zircon.CriteriaView do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view

  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"tool" => tool, "title" => title, "content_flags" => content_flags, "user" => user},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        title: title,
        content_flags: content_flags,
        user: user
      )
    }
  end

  @impl true
  def consume_event(_event, socket) do
    {:stop, socket}
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
