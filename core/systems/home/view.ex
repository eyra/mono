defmodule Systems.Home.View do
  use CoreWeb, :live_component
  import Systems.Home.HTML

  @impl true
  def update(%{blocks: blocks}, socket) do
    {:ok, update_blocks(socket, blocks)}
  end

  defp update_blocks(socket, []), do: socket

  defp update_blocks(socket, [{name, map} | tail]) do
    socket
    |> add_child(name, map)
    |> update_blocks(tail)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-grey6">
        <.intro />
        <.steps />
        <.available_services />
        <.video />
      </div>
    </div>
    """
  end
end
