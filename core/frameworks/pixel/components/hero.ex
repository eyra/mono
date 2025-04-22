defmodule Frameworks.Pixel.Hero do
  @moduledoc """
  The hero is to be used as a large decorative header with page title.
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Image
  alias Frameworks.Pixel.Text

  import Frameworks.Pixel.ImagePreview

  attr(:type, :atom, required: true)
  attr(:params, :map, required: true)

  def dynamic(assigns) do
    ~H"""
    <%= if @type === :illustration1 do %>
      <.illustration1 {@params} />
    <% end %>
    <%= if @type === :illustration2 do %>
      <.illustration2 {@params} />
    <% end %>
    """
  end

  attr(:icon_url, :string, required: true)
  attr(:illustration, :string, default: "/images/illustration2.svg")
  attr(:bg_color, :string, default: "bg-grey1")

  def banner(assigns) do
    ~H"""
    <div class={"relative overflow-hidden w-full h-24 sm:h-32 lg:h-44 #{@bg_color}"}>
      <div class="flex h-full items-center">
        <div class={"flex-wrap ml-6 sm:ml-14 #{@bg_color} bg-opacity-50 z-20 rounded-lg"}>
          <div class="flex items-center">
            <div class="h-20">
              <img class="h-20" src={@icon_url} alt="icon">
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
  attr(:logo_url, :string, default: nil)
  attr(:text_color, :string, default: "text-white")

  def image_banner(assigns) do
    ~H"""
    <div class="w-full h-full" data-native-title={@title}>
      <div class="relative overflow-hidden w-full h-full bg-grey4">
        <%= if @image_info do %>
          <Image.blurhash id="hero" image={@image_info} />
        <% end %>
        <div class="absolute z-20 top-0 left-0 w-full h-full bg-opacity-20 bg-black">
          <div class="ml-6 mr-6 sm:ml-14 sm:mr-14 text-shadow-md h-full">
            <div class="flex flex-col gap-8 h-full justify-center">
              <div class="flex flex-row gap-12 items-center">
                <%= if @logo_url do %>
                <div>
                  <.image_preview
                    image_url={@logo_url}
                    placeholder={"/images/logo_placeholder.svg"}
                    shape="w-[48px] h-[48px] sm:w-[96px] sm:h-[96px] rounded-full"
                  />
                </div>
                <% end %>
                <div class="flex flex-col gap-2">
                  <%= if @title do %>
                    <div class="text-title6 font-title6 sm:text-title2 sm:font-title2 text-white"><%= @title %></div>
                  <% end %>
                  <%= if @subtitle do %>
                  <div class="text-caption font-caption sm:text-title6 sm:font-title6 text-white"><%= @subtitle %></div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
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

  def image_large(assigns) do
    ~H"""
    <div class="w-full h-full" data-native-title={@title}>
      <div class="relative overflow-hidden w-full h-full bg-grey4">
        <%= if @image_info do %>
          <Image.blurhash id="hero" image={@image_info} />
        <% end %>
        <div class="absolute z-20 top-0 left-0 w-full h-full bg-opacity-20 bg-black">
          <div class="ml-6 mr-6 sm:ml-20 sm:mr-20 text-shadow-md h-full">
            <div class="flex flex-col gap-8 h-full">
              <div class="flex-grow" />
              <div class="flex flex-row gap-12">
                <div class="flex flex-col gap-5">
                  <%= if @title do %>
                    <Text.title1 margin="" color="text-white"><%= @title %></Text.title1>
                  <% end %>
                  <%= if @subtitle do %>
                    <Text.title5 align="text-left" color="text-white"><%= @subtitle %></Text.title5>
                  <% end %>
                </div>
              </div>
              <div>
                <%= render_slot(@call_to_action) %>
              </div>
              <div class="flex-grow" />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:illustration, :any, default: "illustration.svg")
  attr(:text_color, :string, default: "text-white")
  attr(:bg_color, :string, default: "bg-primary")

  def illustration1(assigns) do
    ~H"""
    <div
      class={"flex h-hero1 items-center sm:h-hero1-sm lg:h-hero1-lg #{@text_color} #{@bg_color}"}
      data-native-title={@title}
    >
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          <%= @title %>
          <%= if @subtitle do %>
            <br>
            <%= @subtitle %>
          <% end %>
        </p>
      </div>
      <div class="flex-none h-full w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={ ~p"/images/#{@illustration}"} alt="">
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:illustration, :any, default: "illustration.svg")
  attr(:text_color, :string, default: "text-white")
  attr(:bg_color, :string, default: "bg-primary")

  def illustration2(assigns) do
    ~H"""
    <div
      class={"flex h-hero2 items-center sm:h-hero2-sm lg:h-hero2-lg #{@text_color} #{@bg_color} overflow-hidden"}
      data-native-title={@title}
    >
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          <%= @title %>
        </p>
      </div>
      <div class="flex-none h-full w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={~p"/images/#{@illustration}"} alt="">
      </div>
    </div>
    """
  end
end
