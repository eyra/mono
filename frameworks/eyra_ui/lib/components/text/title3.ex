defmodule EyraUI.Text.Title3 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :string, default: "text-grey1")
  prop(margin, :string, default: "mb-5")

  def render(assigns) do
    ~H"""
    <div class="text-title5 font-title5 sm:text-title4 sm:font-title4 lg:text-title3 lg:font-title3 {{ @margin }} {{@color}}">
      <slot />
    </div>
    """
  end
end
