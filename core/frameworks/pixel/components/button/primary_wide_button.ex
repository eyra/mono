defmodule Frameworks.Pixel.Button.PrimaryWideButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(to, :string, required: true)
  prop(label, :string, required: true)
  prop(bg_color, :string, required: true)

  def render(assigns) do
    ~F"""
    <LiveRedirect to={@to}>
      <div class={"flex w-full #{@bg_color} rounded justify-center items-center pl-4 pr-4"}>
        <div class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button">
              {@label}
            </div>
          </div>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
