defmodule Systems.Manual.PageView do
  use CoreWeb, :live_component

  @impl true
  def update(%{page: page}, socket) do
    {:ok, socket |> assign(page: page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Page View</h1>
    </div>
    """
  end
end
