defmodule Frameworks.Pixel.Form.ValidationErrors do
  @moduledoc false
  use Surface.Component
  import Frameworks.Pixel.ErrorHelpers

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(reserve_error_space, :boolean, default: true)

  def render(assigns) do
    ~F"""
    <div x-show={"(focus === '#{@field}' || #{!has_error?(@form, @field)}) && #{@reserve_error_space}"} class="h-18px" ></div>
    <div x-show={"focus !== '#{@field}' && #{has_error?(@form, @field)}"} class="text-warning text-caption font-caption">
      {error_tag(@form, @field)}
    </div>
    """
  end
end
