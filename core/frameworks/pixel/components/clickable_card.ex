defmodule Frameworks.Pixel.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Button

  @impl true
  def handle_event("card_click", _params, socket) do
    client_event_data =
      if socket.assigns.click_event_data,
        do: socket.assigns.click_event_data,
        else: socket.assigns.id

    send(self(), {:card_click, client_event_data})
    {:noreply, socket}
  end

  defp has_actions?(%{left_actions: [_ | _]}), do: true
  defp has_actions?(%{right_actions: [_ | _]}), do: true
  defp has_actions?(_), do: false

  attr(:bg_color, :string, default: "grey6")
  attr(:size, :string, default: "h-full")
  attr(:click_event_name, :string, default: "handle_click")
  attr(:click_event_data, :string)
  attr(:left_actions, :list, default: [])
  attr(:right_actions, :list, default: [])

  slot(:inner_block, required: true)
  slot(:top, default: nil)
  slot(:title, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div
      x-data="{actions: false}"
      class={"h-full rounded-lg cursor-pointer bg-#{@bg_color} #{@size}"}
      phx-click="card_click"
      phx-target={@myself}
    >
      <div class="flex flex-col h-full">
        <%= if @top do render_slot(@top) end %>
        <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-8">
          <%= render_slot(@title) %>
        </div>
        <div class="flex-grow" />
        <div>
          <div
            x-on:mouseover={"actions = #{has_actions?(assigns)}"}
            x-on:mouseover.away="actions = false"
            class="relative pl-6 pr-6 pb-6 lg:pl-8 lg:pr-8 lg:pb-8"
          >
            <div
              x-show="actions"
              class="absolute z-10 -bottom-2px left-0 w-full pl-6 pr-6 pb-6 lg:pl-8 lg:pr-8 lg:pb-8"
            >
              <div class="flex flex-row gap-4 items-center">
                <%= for button <- @left_actions do %>
                  <Button.dynamic {button} />
                <% end %>
                <div class="flex-grow" />
                <%= for button <- @right_actions do %>
                  <Button.dynamic {button} />
                <% end %>
              </div>
            </div>
            <div x-bind:class="{ 'opacity-0': actions, 'opacity-100': !actions }">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
