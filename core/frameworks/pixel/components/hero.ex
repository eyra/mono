defmodule Frameworks.Pixel.Hero do
  @moduledoc """
  The hero is to be used as a large decorative header with page title.
  """
  use CoreWeb, :html

  alias Frameworks.Pixel.Icon
  alias Frameworks.Pixel.Image

  attr(:title, :string, required: true)
  attr(:illustration, :string, default: "/images/illustration.svg")
  attr(:text_color, :string, default: "text-white")
  attr(:bg_color, :string, default: "bg-primary")

  def small(assigns) do
    ~H"""
    <div
      class={"flex h-header2 items-center sm:h-header2-sm lg:h-header2-lg #{@text_color} #{@bg_color} overflow-hidden"}
      data-native-title={@title}
    >
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          <%= @title %>
        </p>
      </div>
      <div class="flex-none h-header2 sm:h-header2-sm lg:h-header2-lg w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={@illustration} alt="">
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:icon_url, :string, required: true)
  attr(:illustration, :string, default: "/images/illustration2.svg")
  attr(:bg_color, :string, default: "bg-grey1")

  def banner(assigns) do
    ~H"""
    <div class={"relative overflow-hidden w-full h-24 sm:h-32 lg:h-44 #{@bg_color}"}>
      <div class="flex h-full items-center">
        <div class={"flex-wrap ml-6 sm:ml-14 #{@bg_color} bg-opacity-50 z-20 rounded-lg"}>
          <div class="flex items-center">
            <div class="">
              <Icon.hero url={@icon_url} />
            </div>
            <div class="ml-6 mr-4 sm:ml-8">
              <Text.title4 color="text-white">
                <div><%= @title %></div>
                <div class="mb-1" />
                <div><%= @subtitle %></div>
              </Text.title4>
            </div>
          </div>
        </div>
        <div class="absolute z-10 bottom-0 right-0 object-scale-down flex-wrap h-full flex-shrink-0">
          <img class="object-scale-down h-full" src={@illustration} alt="">
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:image_info, :any, required: true)
  attr(:text_color, :string, default: "text-white")
  slot(:call_to_action)

  def image(assigns) do
    ~H"""
    <div class="w-full" data-native-title={@title}>
      <div class="relative overflow-hidden w-full h-image-header sm:h-image-header-sm bg-grey4">
        <%= if @image_info do %>
          <Image.blurhash id="hero" {@image_info} transition="duration-1000" />
        <% end %>
        <div class="absolute z-20 top-0 left-0 w-full h-full flex items-center  bg-opacity-20 bg-black">
          <div class="ml-6 mr-6 sm:ml-20 sm:mr-20 text-shadow-md flex-wrap">
            <Text.title0 color="text-white"><%= @title %></Text.title0>
            <.spacing value="S" />
            <Text.title4 color="text-white"><%= @subtitle %></Text.title4>
            <.spacing value="S" />
            <div>
              <%= render_slot(@call_to_action) %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:illustration, :string, default: "/images/illustration.svg")
  attr(:size, :string, default: "large")
  attr(:text_color, :string, default: "text-white")
  attr(:bg_color, :string, default: "bg-primary")

  def large(assigns) do
    ~H"""
    <div
      class={"flex h-header1 items-center sm:h-header1-sm lg:h-header1-lg mb-9 lg:mb-16 #{@text_color} #{@bg_color}"}
      data-native-title={@title}
    >
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          <%= @title %>
          <br>
          <%= @subtitle %>
        </p>
      </div>
      <div class="flex-none w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={@illustration} alt="">
      </div>
    </div>
    """
  end
end
