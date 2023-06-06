defmodule Frameworks.Pixel.Card do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use CoreWeb, :html

  alias Frameworks.Pixel.Text

  attr(:bg_color, :string, default: "bg-grey6")
  attr(:size, :string, default: "h-full")

  slot(:inner_block, required: true)
  slot(:image)
  slot(:title, required: true)

  def normal(assigns) do
    ~H"""
    <div class={"relative rounded-lg cursor-pointer #{@bg_color} #{@size}"}>
      <%= render_slot(@image) %>
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <%= render_slot(@title) %>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:image, :string, required: true)
  attr(:event, :string, required: true)

  def button(assigns) do
    ~H"""
    <div
      phx-click={@event}
      class="bg-transparent h-full w-full rounded-md border-2 border-grey3 border-dashed hover:border-grey6 hover:bg-grey6 cursor-pointer"
    >
      <div class="flex flex-col items-center justify-center h-full w-full pl-11 pr-11 md:pl-20 md:pr-20 lg:pl-10 lg:pr-10 pt-16 pb-16">
        <div class="mb-6">
          <img src={@image} alt="">
        </div>
        <div class="w-full mb-9 text-grey1 text-title5 font-title5 lg:text-title4 lg:font-title4 text-center">
          <%= @title %>
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:text, :string, required: true)

  def highlight(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <div class="text-center ml-6 mr-6">
        <div class="mt-6 mb-7 sm:mt-8 sm:mb-9">
          <Text.title5 color="text-primary"><%= @title %></Text.title5>
          <div class="mb-1 sm:mb-2" />
          <Text.title5><%= @text %></Text.title5>
        </div>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:button_label, :string, required: true)
  attr(:to, :string, required: true)
  attr(:button_bg_color, :string, default: "bg-white")

  def primary_cta(assigns) do
    ~H"""
    <.normal bg_color="bg-grey1">
      <:title>
        <div class="text-white text-title5 font-title5 lg:text-title3 lg:font-title3">
          <%= @title %>
        </div>
      </:title>
      <div class="mt-6 lg:mt-8">
        <div class="flex items-center">
          <div class="flex-wrap">
            <Button.Action.redirect to={@to}>
              <div class={"flex items-center active:opacity-80 focus:outline-none pl-4 pr-4 h-48px font-button text-button text-primary tracker-widest rounded #{@button_bg_color}"}>
                <div><%= @button_label %></div>
              </div>
            </Button.Action.redirect>
          </div>
          <div class="flex-grow" />
        </div>
      </div>
    </.normal>
    """
  end

  attr(:text, :string, required: true)
  attr(:type, :atom, default: :primary)

  def label(%{type: type} = assigns) do
    image = "label-arrow-#{type}.svg"

    bg_color =
      case type do
        :delete -> "bg-delete"
        :warning -> "bg-warning"
        :success -> "bg-success"
        :primary -> "bg-primary"
        :secondary -> "bg-secondary"
        :tertiary -> "bg-tertiary"
        :disabled -> "bg-grey5"
        type -> "bg-#{type}"
      end

    text_color =
      case type do
        :tertiary -> "text-grey1"
        :disabled -> "text-grey1"
        _ -> "text-white"
      end

    assigns =
      assign(assigns, %{
        bg_color: bg_color,
        text_color: text_color,
        image: image
      })

    ~H"""
    <div class="flex">
      <div class={"h-14 pl-4 pr-2 #{@bg_color}"}>
        <div class="flex flex-row justify-center h-full items-center">
          <Text.title5 color={@text_color}><%= @text %></Text.title5>
        </div>
      </div>
      <img src={~p"/images/#{@image}"} alt={@text}>
    </div>
    """
  end
end
