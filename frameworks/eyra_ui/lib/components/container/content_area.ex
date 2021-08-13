defmodule EyraUI.Container.ContentArea do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)
  prop(top_padding, :css_class, default: "pt-6 md:pt-9 lg:pt-20")

  def render(assigns) do
    ~H"""
    <div class="flex w-full {{ @top_padding }}">
      <div class="flex-grow ml-6 mr-6 lg:ml-14 lg:mr-14">
        <div class="w-full">
          <slot />
        </div>
      </div>
    </div>
    """
  end
end
