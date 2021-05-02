defmodule EyraUI.Form.ValidationErrors do
  @moduledoc false
  use Surface.Component
  import EyraUI.ErrorHelpers

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(reserve_error_space, :boolean, default: true)

  def render(assigns) do
    ~H"""
    <div x-show="(focus === '{{@field}}' || {{ !has_error?(@form, @field) }}) && {{@reserve_error_space}}" class="h-6" ></div>
    <div x-show="focus !== '{{@field}}' && {{ has_error?(@form, @field) }}" class="text-warning font-caption">
      {{ error_tag(@form, @field) }}
    </div>
    """
  end
end
