defmodule Frameworks.Pixel.Card.ClickableCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.LiveComponent

  alias Frameworks.Pixel.Button.DynamicButton

  @doc "The card image"
  slot(image)

  @doc "The card title"
  slot(title)

  @doc "The card content, can be button, description etc."
  slot(default, required: true)

  prop(bg_color, :css_class, default: "grey6")
  prop(size, :css_class, default: "h-full")
  prop(click_event_name, :string, default: "handle_click")
  prop(click_event_data, :string)
  prop(left_actions, :list, default: [])
  prop(right_actions, :list, default: [])

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

  def render(assigns) do
    ~F"""
    <div
      x-data="{actions: false}"
      class={"rounded-lg cursor-pointer bg-#{@bg_color} #{@size}"} :on-click="card_click"
    >
      <div class="flex flex-col h-full">
        <#slot name="image" />
        <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-8" >
          <#slot name="title" />
        </div>
        <div class="flex-grow"></div>
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
                <DynamicButton :for={button <- @left_actions} vm={button} />
                <div class="flex-grow"></div>
                <DynamicButton :for={button <- @right_actions} vm={button} />
              </div>
            </div>
            <div x-bind:class="{ 'opacity-0': actions, 'opacity-100': !actions }">
              <#slot />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Card.ClickableCard.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Card.ClickableCard,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "420px",
    container: {:div, class: ""}

  alias Frameworks.Pixel.Image

  def handle_info({:card_click, id}, socket) do
    IO.puts("card_click: campaign ##{id}")
    {:noreply, socket}
  end

  def handle_event(event, %{"item" => item}, socket) do
    IO.puts("#{event}: campaign ##{item}")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <ClickableCard id={23} bg_color="grey1"
      left_actions={[
        %{
          action: %{type: :send, event: "action1", item: "1"},
          face: %{type: :label, label: "Action1", font: "text-subhead font-subhead", text_color: "text-white", wrap: true}
        },
        %{
          action: %{type: :send, event: "action2", item: "1"},
          face: %{type: :label, label: "Action2", font: "text-subhead font-subhead", text_color: "text-white", wrap: true}
        }
      ]}
      right_actions={[
        %{
          action: %{type: :send, event: "delete", item: "1"},
          face: %{type: :icon, icon: :delete, alt: "delete", color: :white}
        }
      ]}
    >
      <#template slot="image">
        <div class="h-image-card">
          <Image image={Core.ImageHelpers.get_image_info(nil, 400, 300)} transition="duration-500" corners="rounded-t-lg"/>
        </div>
      </#template>
      <#template slot="title">
        <div class="text-title5 font-title5 lg:text-title3 lg:font-title3 text-white">
          This is an example title
        </div>
      </#template>
      <div>
      </div>
    </ClickableCard>
    """
  end
end
