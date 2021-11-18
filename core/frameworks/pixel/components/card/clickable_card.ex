defmodule Frameworks.Pixel.Card.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.LiveComponent

  @doc "The card image"
  slot(image)

  @doc "The card title"
  slot(title)

  @doc "The card content, can be button, description etc."
  slot(default, required: true)

  prop(bg_color, :css_class, default: "bg-grey6")
  prop(size, :css_class, default: "h-full")
  prop(click_event_name, :string, default: "handle_click")
  prop(click_event_data, :string)

  def handle_event("card_click", _params, socket) do
    client_event_data =
      if socket.assigns.click_event_data,
        do: socket.assigns.click_event_data,
        else: socket.assigns.id

    send(self(), {:card_click, client_event_data})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="rounded-lg cursor-pointer {{@bg_color}} {{@size}}" :on-click="card_click">
      <slot name="image" />
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <slot name="title" />
        <slot />
      </div>
    </div>
    """
  end
end
