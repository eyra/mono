defmodule Frameworks.Pixel.Paginator do
  @moduledoc false
  use CoreWeb, :pixel

  attr(:active_page, :integer, required: true)
  attr(:page_count, :integer, required: true)
  attr(:window_size, :integer, default: 7)
  attr(:target, :any, default: "")

  def paginator(%{page_count: page_count} = assigns) when page_count < 2 do
    ~H"""
      <div class="flex flex-row justify-center gap-2">
        <.previous_page_button active_page={@active_page} target={@target} />
        <.next_page_button active_page={@active_page} page_count={@page_count} target={@target} />
      </div>
    """
  end

  def paginator(
        %{active_page: active_page, page_count: page_count, window_size: window_size} = assigns
      ) do
    window_start = max(0, active_page - div(window_size, 2))
    window_end = min(page_count - 1, window_start + window_size - 1)

    assigns =
      assign(assigns, %{
        window_start: window_start,
        window_end: window_end
      })

    ~H"""
      <div class="flex flex-row justify-center gap-2">
        <.previous_page_button active_page={@active_page} target={@target} />
        <%= for page_index <- @window_start..@window_end do %>
          <.page_button index={page_index} active?={page_index == @active_page} target={@target} />
        <% end %>
        <.next_page_button active_page={@active_page} page_count={@page_count} target={@target} />
      </div>
    """
  end

  attr(:active_page, :integer, required: true)
  attr(:target, :any, default: "")

  def previous_page_button(assigns) do
    ~H"""
      <div
        class="w-8 h-8 flex items-center justify-center cursor-pointer"
        phx-click="select_page"
        phx-value-item={max(0, @active_page - 1)}
        phx-target={@target}
    >
        <img src="/images/icons/back.svg" alt="Back" />
      </div>
    """
  end

  attr(:active_page, :integer, required: true)
  attr(:page_count, :integer, required: true)
  attr(:target, :any, default: "")

  def next_page_button(assigns) do
    ~H"""
      <div
        class="w-8 h-8 flex items-center justify-center cursor-pointer  "
        phx-click="select_page"
        phx-value-item={min(@page_count - 1, @active_page + 1)}
        phx-target={@target}
      >
        <img src="/images/icons/forward.svg" alt="Forward" />
      </div>
    """
  end

  attr(:index, :integer, required: true)
  attr(:active?, :boolean, required: true)
  attr(:target, :any, default: "")

  def page_button(%{active?: active?} = assigns) do
    dynamic_style =
      if active? do
        "bg-primary text-white"
      else
        "bg-grey5 text-grey2"
      end

    assigns = assign(assigns, dynamic_style: dynamic_style)

    ~H"""
      <div
        class={"rounded w-8 h-8 flex items-center justify-center font-label text-label cursor-pointer #{@dynamic_style}"}
        phx-click="select_page"
        phx-value-item={@index}
        phx-target={@target}>
        <%= @index + 1 %>
      </div>
    """
  end
end
