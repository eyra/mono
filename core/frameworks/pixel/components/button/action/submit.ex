defmodule Frameworks.Pixel.Button.Action.Submit do
  @moduledoc """
  Submits form and optionally triggers alpine functionality on top of that
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    code: nil,
    form_id: nil
  )

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <button
      :if={not has_form_id?(@vm)}
      @click={code(@vm)}
      type="submit"
      class="cursor-pointer focus:outline-none"
    >
      <#slot />
    </button>
    <button
      :if={has_form_id?(@vm)}
      @click={code(@vm)}
      type="submit"
      class="cursor-pointer focus:outline-none"
      form={form_id(@vm)}
    >
      <#slot />
    </button>
    """
  end
end
