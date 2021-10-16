defmodule CoreWeb.UI.Navigation.ButtonBar do
  @moduledoc false
  use CoreWeb.UI.Component

  alias EyraUI.Button.DynamicButton

  prop(buttons, :list, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex flex-row gap-4 items-center">
      <DynamicButton :for={{ button <- @buttons }} vm={{ button }} />
    </div>
    """
  end
end
