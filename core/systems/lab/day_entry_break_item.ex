defmodule Systems.Lab.DayEntryBreakItem do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Line

  def render(assigns) do
    ~F"""
      <div class="flex flex-row items-center h-6 w-full">
        <div class="h-1px w-full">
          <Line />
        </div>
      </div>
    """
  end
end
