defmodule CoreWeb.UI.Container.RestrictedWidthArea do
  @moduledoc """
    Restricted width container for forms.
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Container.{FormArea, SheetArea, FullpageArea}

  prop(type, :atom, required: true)

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <FormArea :if={@type === :form}>
      <#slot />
    </FormArea>
    <SheetArea :if={@type === :sheet}>
      <#slot />
    </SheetArea>
    <FullpageArea :if={@type === :fullpage}>
      <#slot />
    </FullpageArea>
    """
  end
end
