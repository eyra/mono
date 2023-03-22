defmodule Systems.Org.ItemView do
  use CoreWeb.UI.Component
  alias Frameworks.Pixel.Panel.ClickablePanel
  alias Frameworks.Pixel.Tag

  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(tags, :list, default: [])
  prop(title_color, :css_class, default: "text-grey1")
  prop(description_color, :css_class, default: "text-grey1")
  prop(event, :string, default: "handle_item_click")
  prop(item, :string, required: true)
  prop(target, :string, default: "")

  def render(assigns) do
    ~F"""
    <ClickablePanel
      size="w-full h-full"
      bg_color="bg-grey5"
      event={@event}
      item={@item}
      target={@target}
    >
      <:title>
        <div class={"text-title3 font-title3 #{@title_color}"}>
          {@title}
        </div>
      </:title>
      <Spacing value="M" />
      <div class={"text-subhead", "font-subhead", @description_color}>
        <span class="whitespace-pre-wrap">{@description}</span>
      </div>
      <Spacing value="M" />
      <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
        <Tag :for={tag <- @tags} text={tag} />
      </div>
    </ClickablePanel>
    """
  end
end
