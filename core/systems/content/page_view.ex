defmodule Systems.Content.PageView do
  use CoreWeb, :live_component

  alias Systems.Content

  @impl true
  def update(%{title: title, page: %Content.PageModel{body: body}}, socket) do
    {
      :ok,
      socket |> assign(title: title, body: body)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Text.title2 align="text-left"><%= @title %></Text.title2>
        <div class="wysiwyg">
          <%= raw @body %>
        </div>
      </div>
    """
  end
end
