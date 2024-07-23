defmodule Frameworks.Pixel.Separator do
  use CoreWeb, :html

  attr(:type, :atom, required: true)

  def dynamic(assigns) do
    ~H"""
      <%= if @type == :forward do %>
        <.forward />
      <% end %>
    """
  end

  def forward(assigns) do
    ~H"""
      <div class="w-6 h-6">
        <img src="/images/icons/forward_grey2.svg" />
      </div>
    """
  end
end
