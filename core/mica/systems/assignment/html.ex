defmodule Systems.Assignment.Html do
  use CoreWeb, :html

  slot(:inner_block, required: true)

  def task_list(assigns) do
    ~H"""
      <div class="w-full h-full md:flex md:flex-row md:justify-center md:pt-12 lg:pt-20">
        <div class="w-full md:max-w-[640px] px-6 pt-6 md:px-0 flex-shrink-0">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    """
  end
end
