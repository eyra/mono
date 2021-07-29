defmodule EyraUI.Navigation.Get do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <a
        class="cursor-pointer"
        data-phx-link="redirect"
        data-phx-link-state="replace"
        href={{ @path }}
      >
        <slot />
      </a>
    """
  end
end
