defmodule Frameworks.Pixel.FilterBar do
  @moduledoc false
  use CoreWeb, :html

  attr(:items, :list, required: true)

  def filter_bar(assigns) do
    ~H"""
    <div class="flex flex-row gap-3 items-center">
      <%= for item <- @items do %>
        <div>
          <div
            class="cursor-pointer select-none"
            phx-click="toggle-filter"
            phx-value-item={"#{item.id}"}
          >
            <div class={"rounded-full px-6 py-3 text-label font-label select-none #{if item.active, do: "bg-primary text-white", else: "bg-grey5 text-grey2"} "}>
              <%= item.value %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
