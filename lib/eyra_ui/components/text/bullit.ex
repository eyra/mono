defmodule EyraUI.Text.Bullet do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component
  alias LinkWeb.Router.Helpers, as: Routes

  prop socket, :map, required: true
  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="flex items-center mb-3">
      <div class="flex-wrap h-3 w-3 mr-3 flex-shrink-0">
        <img src={{ Routes.static_path(@socket, "/images/bullit.svg") }} />
      </div>
      <div class="flex-grow font-body text-bodymedium lg:text-bodylarge">
        <slot />
      </div>
    </div>
    """
  end
end
