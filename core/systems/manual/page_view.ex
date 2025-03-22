defmodule Systems.Manual.PageView do
  use CoreWeb, :live_component

  alias Systems.Userflow

  @impl true
  def update(%{page: page, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(page: page, user: user)
      |> mark_visited()
    }
  end

  defp mark_visited(%{assigns: %{page: %{userflow_step: userflow_step}, user: user}} = socket) do
    Userflow.Public.mark_visited(userflow_step, user)
    socket
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
