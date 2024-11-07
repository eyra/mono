defmodule Frameworks.Pixel.LoadingSpinner do
  use CoreWeb, :pixel

  attr(:size, :string, default: "w-6 h-6")
  attr(:show_loading_text?, :boolean, default: false)
  attr(:loading_text, :string, default: "Loading")

  def primary(assigns) do
    ~H"""
      <div class="flex w-full h-full items-center justify-between gap-2">
        <div class={"#{@size} animate-spin"}>
          <img src={~p"/images/icons/loading_primary@3x.png"} alt={"Loading"}>
        </div>
        <%= if @show_loading_text? do %>
          <div class="font-light text-grey2">
            <%= @loading_text %>
          </div>
        <% end %>
      </div>
    """
  end

  def secondary(assigns) do
    ~H"""
      <div class="flex w-full h-full items-center justify-between gap-2">
        <div class={"#{@size} animate-spin"}>
          <img src={~p"/images/icons/loading_white@3x.png"} alt={"Loading"}>
        </div>
        <%= if @show_loading_text? do %>
          <div class="font-light text-grey2">
            <%= @loading_text %>
          </div>
        <% end %>
      </div>
    """
  end

  attr(:progress, :integer, default: 0)

  def progress_spinner(assigns) do
    ~H"""
    <div class="animate-spin">
      <svg width="30" height="30" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r="45" fill="none" stroke="#e0e0e0" stroke-width="10"/>
        <circle cx="50" cy="50" r="45" fill="none" stroke="#3b82f6" stroke-width="10"
                stroke-linecap="round"
                stroke-dasharray="282.6"
                stroke-dashoffset={calculate_offset(@progress)}
                />
      </svg>
    </div>
    """
  end

  defp calculate_offset(progress) do
    282.6 - 282.6 * progress / 100
  end
end
