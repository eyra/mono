defmodule CoreWeb.UI.Navigation.Tab do
  @moduledoc false
  use CoreWeb.UI.Component

  prop(id, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div id="tab_{{ @id}}" class="hidden">
      <slot />
    </div>
    """
  end
end
