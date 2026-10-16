defmodule Frameworks.Pixel.Empty do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:illustration, :string)
  attr(:button, :map, default: nil)

  def empty(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10 gap-y-8">
      <div>
        <Text.title1><%= @title %></Text.title1>
        <div class="text-bodymedium sm:text-bodylarge font-body">
          <%= @body %>
        </div>
        <%= if @button do %>
        <div>
          <.spacing value="L" />
          <.wrap>
            <Button.dynamic {@button} />
          </.wrap>
        </div>
        <% end %>
      </div>
      <div class="w-full mt-6 hidden md:block">
        <img
          class="object-fill w-full"
          src={~p"/images/illustrations/#{"#{@illustration}.svg"}"}
          alt=""
        />
      </div>
    </div>
    """
  end
end
