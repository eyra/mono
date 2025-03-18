defmodule Manual.ChapterMobileView do
  use CoreWeb, :live_component

  @impl true
  def update(%{chapter: chapter}, socket) do
    {
      :ok,
      socket
      |> assign(chapter: chapter)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Mobile Chapter View
    </div>
    """
  end
end
