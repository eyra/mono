defmodule Systems.Manual.PageView do
  use CoreWeb, :live_component

  @impl true
  def update(%{page: page}, socket) do
    {
      :ok,
      socket
      |> assign(page: page)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-8">
      <Text.title2 margin=""><%= @page.title %></Text.title2>
      <%= if @page.image do %>
        <div>
          <img src={@page.image} />
        </div>
      <% end %>
      <div class="wysiwyg">
        <%= raw @page.text %>
      </div>
    </div>
    """
  end
end
