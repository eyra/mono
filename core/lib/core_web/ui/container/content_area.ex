defmodule CoreWeb.UI.Container.ContentArea do
  @moduledoc """
  Main container for content sections on a page.
  """
  use CoreWeb.UI.Component

  @doc "The content"
  slot(default, required: true)

  prop(class, :string, default: "")

  def render(assigns) do
    ~H"""
    <div class="flex w-full {{ @class }}">
      <div class="flex-grow ml-6 mr-6 lg:ml-14 lg:mr-14">
        <div class="w-full">
          <slot />
        </div>
      </div>
    </div>
    """
  end
end
