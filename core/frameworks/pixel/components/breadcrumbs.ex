defmodule Frameworks.Pixel.Breadcrumbs do
  use CoreWeb, :live_component

  @impl true
  def update(%{elements: elements}, %{assigns: %{}} = socket) do
    {
      :ok,
      socket
      |> assign(elements: elements)
      |> update_blocks()
    }
  end

  defp update_blocks(%{assigns: %{elements: elements}} = socket) do
    count = Enum.count(elements)

    blocks =
      elements
      |> Enum.with_index()
      |> Enum.map(fn {element, index} -> map_to_block(element, index + 1 == count) end)
      |> Enum.intersperse({:separator, %{type: :forward}})

    assign(socket, blocks: blocks)
  end

  defp map_to_block(%{label: label, path: path}, last?) do
    {
      :button,
      %{
        face: %{
          type: :plain,
          label: label,
          text_color:
            if last? do
              "text-primary"
            else
              "text-grey2"
            end
        },
        action: %{type: :send, event: "handle_click", item: path}
      }
    }
  end

  @impl true
  def handle_event("handle_click", %{"item" => path}, socket) do
    {:noreply, socket |> push_navigate(to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="h-full w-full overflow-scroll">
        <div class="flex flex-row items-center gap-2 h-full">
          <%= for {type, value} <- @blocks do %>
            <%= if type == :separator do %>
              <div class="flex-shrink-0">
                <Separator.dynamic {value} />
              </div>
            <% end %>
            <%= if type == :button do %>
              <div class="flex-shrink-0">
                <Button.dynamic {value} />
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    """
  end
end
