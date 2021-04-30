defmodule EyraUI.Form.ValidationErrors do
  @moduledoc false
  use Surface.Component
  import EyraUI.ErrorHelpers, only: [error_tag: 2, has_error?: 2]

  prop(field, :atom, required: true)

  def render(assigns) do
    ~H"""
    <Context get={{ Surface.Components.Form, form: form }}>
      <span class="text-warning font-caption mt-1"
            :if={{has_error?(form, @field)}}>
        {{ error_tag form, @field }}
      </span>
    </Context>
    """
  end
end
