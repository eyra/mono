defmodule Systems.Assignment.StartView do
  use CoreWeb, :html

  alias Frameworks.Pixel.Align
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  attr(:id, :any, required: true)
  attr(:title, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:description, :string, required: true)
  attr(:button, :map, required: true)

  def start_view(assigns) do
    ~H"""
      <div class="w-full h-full pl-16 pb-16 pr-16">
        <Align.horizontal_center>
        <Area.sheet>
          <div class="flex flex-col gap-8 items-center">
            <%= if @icon do %>
              <div>
                <img class="w-24 h-24" src={"/images/icons/#{@icon}.svg"} alt={@icon}>
              </div>
            <% end %>

            <Text.title2 margin=""><%= @title %></Text.title2>
            <Text.body align="text-center"><%= @description %></Text.body>
            <.wrap>
              <Button.dynamic {@button} />
            </.wrap>
          </div>
        </Area.sheet>
        </Align.horizontal_center>
      </div>
    """
  end
end
