defmodule CoreWeb.UI.Dialog do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Button.DynamicButton

  prop(title, :string, required: true)
  prop(text, :string, required: true)
  prop(buttons, :string, default: [])

  slot(default)

  def render(assigns) do
    ~F"""
    <div class="p-8 bg-white shadow-2xl min-w-dialog-width sm:min-w-dialog-width-sm rounded">
      <div class="flex flex-col gap-4 sm:gap-8">
        <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
          {@title}
        </div>
        <div class="text-bodymedium font-body sm:text-bodylarge">
          {@text}
        </div>
        <#slot />
        <div class="flex flex-row gap-4">
          <DynamicButton :for={button <- @buttons} vm={button} />
        </div>
      </div>
    </div>
    """
  end
end
