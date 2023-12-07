defmodule Frameworks.Pixel.Takeover do
  use CoreWeb, :html

  alias Frameworks.Pixel.Button

  attr(:title, :string, required: true)
  attr(:target, :any, required: true)

  slot(:inner_block)

  def takeover(%{target: target} = assigns) do
    close_button = %{
      action: %{type: :send, event: "takeover_close", target: target},
      face: %{type: :icon, icon: :close}
    }

    assigns = assign(assigns, close_button: close_button)

    ~H"""
    <div class="px-12 pt-6 pb-12 bg-white shadow-floating rounded relative">
      <div class="sticky top-10">
        <div class="flex flex-row">
          <div class="flex-grow" />
          <Button.dynamic {@close_button} />
        </div>
      </div>
      <div class="flex flex-col">
        <Text.title2><%= @title %></Text.title2>
        <div class="">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
