defmodule CoreWeb.UI.Navigation.ActionMenu do
  @moduledoc false
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Button.DynamicButton

  prop(buttons, :list, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-col justify-left -gap-1 p-6 rounded bg-white shadow-2xl w-action_menu-width">
      <DynamicButton :for={button <- @buttons} vm={button} />
    </div>
    """
  end
end
