defmodule EyraUI.Container.ContentArea do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex w-full pt-6 md:pt-9 lg:pt-20">
      <div class="flex-grow ml-6 mr-6 lg:ml-14 lg:mr-14">
        <div class="w-full">
          <slot />
        </div>
      </div>
      <div class="flex-wrap flex-shrink-0 w-0 lg:w-sidebar">
      </div>
    </div>
    """
  end
end
