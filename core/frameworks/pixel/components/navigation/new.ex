defmodule Frameworks.Pixel.Navigation.New do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~F"""
      <a
        class="cursor-pointer"
        href={@path}
        data-to={@path}
        data-method="new"
        data-csrf={Plug.CSRFProtection.get_csrf_token_for(@path)}
      >
        <#slot />
      </a>
    """
  end
end
