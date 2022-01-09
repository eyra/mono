defmodule CoreWeb.UI.Container.FormArea do
  @moduledoc """
    Restricted width container for forms.
  """
  use CoreWeb.UI.Component

  prop(class, :string, default: "")

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class={"flex justify-center #{@class}"}>
      <div class="flex-grow sm:max-w-form">
        <#slot />
      </div>
    </div>
    """
  end
end
