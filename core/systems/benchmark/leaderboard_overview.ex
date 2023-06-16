defmodule Systems.Benchmark.LeaderboardOverview do
  use CoreWeb, :live_component

  @impl true
  def update(%{id: id}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div />
    """
  end
end
