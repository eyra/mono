defmodule Frameworks.Pixel.Toolbar do
  use CoreWeb, :pixel

  require Logger

  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Button

  attr(:back_button, :map, required: true)
  attr(:left_button, :map, default: nil)
  attr(:right_button, :map, default: nil)

  def toolbar(%{left_button: nil, right_button: nil} = assigns) do
    ~H"""
    <div class="w-full h-full bg-white">
      <div class="px-4">
        <.line />
        <div class="flex flex-row w-full h-[56px] justify-start xl:justify-center">
            <Button.dynamic {@back_button} />
        </div>
      </div>
    </div>
    """
  end

  def toolbar(assigns) do
    ~H"""
      <div class="w-full h-full bg-white">
        <div class="px-4 sm:px-8">
          <.line />
          <div class="flex flex-row w-full h-[56px] gap-8">
            <Button.dynamic {@back_button} />
            <div class="flex-grow" />
            <%= if @left_button do %>
              <Button.dynamic {@left_button} />
            <% end %>
            <%= if @right_button do %>
              <Button.dynamic {@right_button} />
            <% end %>
          </div>
        </div>
      </div>
    """
  end
end
