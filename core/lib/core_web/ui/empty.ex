defmodule CoreWeb.UI.Empty do
  use CoreWeb, :html

  alias Frameworks.Pixel.Text

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:illustration, :string, default: "cards")

  def empty(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10 gap-y-8">
      <div>
        <Text.title1><%= @title %></Text.title1>
        <div class="text-bodymedium sm:text-bodylarge font-body">
          <%= @body %>
        </div>
      </div>
      <div class="w-full mt-6 md:mt-0">
        <img
          class="hidden md:block object-fill w-full"
          src={"/images/illustrations/#{@illustration}.svg"}
          alt=""
        />
        <img
          class="md:hidden object-fill w-full"
          src={"/images/illustrations/#{@illustration}_mobile.svg"}
          alt=""
        />
      </div>
    </div>
    """
  end
end
