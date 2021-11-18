defmodule Frameworks.Pixel.Navigation.Alpine do
  use Surface.Component

  prop(click_handler, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <div class="focus:outline-none cursor-pointer"
        @click={{@click_handler}}
      >
        <slot />
      </div>
    """
  end
end
