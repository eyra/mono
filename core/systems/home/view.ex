defmodule Systems.Home.View do
  use CoreWeb, :live_component

  @impl true
  def update(%{blocks: blocks}, socket) do
    {
      :ok,
      socket
      |> update_blocks(blocks)
    }
  end

  def update_blocks(socket, []), do: socket

  def update_blocks(socket, [{name, map} | tail]) do
    socket
    |> add_child(name, map)
    |> update_blocks(tail)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Margin.y id={:page_top} />
      <Area.content>
        <.stack fabric={@fabric} gap="gap-14"/>
      </Area.content>
    </div>
    """
  end
end
