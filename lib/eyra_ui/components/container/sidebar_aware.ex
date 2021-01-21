defmodule EyraUI.Container.SidebarAware do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component

  @doc "The content"
  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="flex h-full w-full">
      <div class="flex-grow">
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
