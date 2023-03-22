defmodule Systems.Pool.ItemView do
  @moduledoc """
  The Pool Card displays information about a participant pool.
  """
  use CoreWeb.UI.Component
  alias Frameworks.Pixel.Panel.ClickablePanel
  alias Frameworks.Pixel.Tag

  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(tags, :list, default: [])
  prop(title_color, :css_class, default: "text-grey1")
  prop(description_color, :css_class, default: "text-grey1")
  prop(event, :string, default: "handle_pool_click")
  prop(item, :string, required: true)
  prop(target, :any, default: false)

  prop(left_actions, :list, default: [])
  prop(right_actions, :list, default: [])

  def render(assigns) do
    ~F"""
    <ClickablePanel
      size="w-full h-full"
      bg_color="bg-grey5"
      event={@event}
      target={@target}
      item={@item}
    >
      <:title>
        <div class={"text-title3 font-title3 #{@title_color}"}>
          {@title}
        </div>
      </:title>
      <Spacing value="M" />
      <div class="flex flex-col gap-8">
        <div class={"text-subhead", "font-subhead", @description_color}>
          <span class="whitespace-pre-wrap">{@description}</span>
        </div>
        <div :if={Enum.count(@tags) > 0} class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
          <Tag :for={tag <- @tags} text={tag} />
        </div>
        <div
          :if={Enum.count(@left_actions) > 0 or Enum.count(@right_actions) > 0}
          class="flex flex-row gap-4 items-center"
        >
          <DynamicButton :for={button <- @left_actions} vm={button} />
          <div class="flex-grow" />
          <DynamicButton :for={button <- @right_actions} vm={button} />
        </div>
      </div>
    </ClickablePanel>
    """
  end
end
