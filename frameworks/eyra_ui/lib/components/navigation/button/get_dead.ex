defmodule EyraUI.Navigation.GetDead do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <a
        class="cursor-pointer"
        x-data="{}"
        href={{ @path }}
      >
        <slot />
      </a>
    """
  end
end
