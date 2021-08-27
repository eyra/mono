defmodule EyraUI.Navigation.New do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <a
        class="cursor-pointer"
        href={{ @path }}
        data-to={{ @path }}
        data-method="new"
        data-csrf={{ Plug.CSRFProtection.get_csrf_token_for(@path) }}
      >
        <slot />
      </a>
    """
  end
end
