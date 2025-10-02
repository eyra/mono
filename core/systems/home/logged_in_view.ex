defmodule Systems.Home.LoggedInView do
  use CoreWeb, :live_component

  @impl true
  def update(%{blocks: blocks}, socket) do
    {:ok, socket |> assign(blocks: blocks) |> update_blocks(blocks)}
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
      <div class="bg-grey6 px-6 lg:px-8 py-6 lg:py-8">
        <div class="space-y-6">
          <%= for {name, _} <- @blocks do %>
            <.child name={name} fabric={@fabric} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
