defmodule EyraUI.Button.SubmitButtonWide do
  @moduledoc false
  use Surface.Component

  @doc "The text to put on the button"
  slot default, required: true
  prop color, :css_class, default: "bg-grey1"
  prop width, :css_class, default: "w-full"

  def render(assigns) do
    ~H"""
    <button class={{"h-48px", "leading-none", "font-button", "text-button", "text-white", "focus:outline-none", "hover:bg-opacity-80", "rounded",
                    @color, @width }}
            type="submit">
     <slot />
    </button>
    """
  end
end
