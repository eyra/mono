defmodule Systems.Manual.View do
  use CoreWeb, :live_component

  @impl true
  def update(_, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Manual</h1>
    </div>
    """
  end
end
