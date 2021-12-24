defmodule CoreWeb.UI.Container.FullpageArea do
  @moduledoc """
  Restricted width container for fullpages. Since fullpages have no width restrictions.
  """
  use CoreWeb.UI.Component

  prop(class, :string, default: "")

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class={@class}>
      <div>
        <#slot />
      </div>
    </div>
    """
  end
end
