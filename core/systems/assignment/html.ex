defmodule Systems.Assignment.Html do
  use CoreWeb, :html

  import Frameworks.Pixel.Line

  slot(:inner_block, required: true)

  def task_list(assigns) do
    ~H"""
      <div class="w-full h-full md:flex md:flex-row md:justify-center md:pt-12 lg:pt-20">
        <div class="w-full md:max-w-[640px] px-6 pt-6 md:px-0 flex-shrink-0 flex flex-col gap-6">
          <div>
            <Text.title2 margin=""><%= dgettext("eyra-assignment", "work.list.title") %></Text.title2>
          </div>
          <div>
            <.line />
          </div>
          <div class="flex-grow">
            <div class="h-full overflow-y-scroll">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </div>
    """
  end
end
