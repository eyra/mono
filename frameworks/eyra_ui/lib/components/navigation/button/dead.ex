defmodule EyraUI.Navigation.Dead do
  use Surface.Component

  prop(path, :string, required: true)
  prop(method, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <a
        class="cursor-pointer"
        href={{ @path }}
        data-to={{ @path }}
        data-method={{ @method }}
        data-csrf={{ Plug.CSRFProtection.get_csrf_token_for(@path) }}
      >
        <slot />
      </a>
    """
  end
end
