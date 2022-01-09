defmodule CoreWeb.UI.Container.ContentArea do
  @moduledoc """
  Main container for content sections on a page.
  """
  use CoreWeb.UI.Component

  @doc "The content"
  slot(default, required: true)

  prop(class, :string, default: "")

  def render(assigns) do
    ~F"""
    <div class={"flex w-full #{@class}"}>
      <div class="flex-grow mx-6 lg:mx-14">
        <div class="w-full">
          <#slot />
        </div>
      </div>
    </div>
    """
  end
end
