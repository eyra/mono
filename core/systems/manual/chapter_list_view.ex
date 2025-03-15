defmodule Systems.Manual.ChapterListView do
  use CoreWeb, :live_component

  @impl true
  def update(%{manual: manual}, socket) do
    {:ok, socket |> assign(manual: manual)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Chapter List</h1>
    </div>
    """
  end
end
