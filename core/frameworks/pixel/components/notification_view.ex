defmodule Frameworks.Pixel.NotificationView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  @impl true
  def update(%{title: title, body: body}, socket) do
    {:ok, socket |> assign(title: title, body: body)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Text.title2><%= @title %></Text.title2>
        <div class="wysiwyg">
          <%= raw @body %>
      </div>
      </div>
    """
  end
end
