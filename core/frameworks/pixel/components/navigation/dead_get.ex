defmodule Frameworks.Pixel.Navigation.DeadGet do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~F"""
      <a
        class="cursor-pointer"
        href={@path}
      >
        <#slot />
      </a>
    """
  end
end
