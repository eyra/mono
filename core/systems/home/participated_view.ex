defmodule Systems.Home.ParticipatedView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Content

  @impl true
  def update(%{content_items: content_items}, socket) do
    {
      :ok,
      socket |> assign(content_items: content_items)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2>
        <%= dgettext("eyra-home", "participated.title") %>
        <span class="text-primary"> <%= Enum.count(@content_items) %></span>
      </Text.title2>
      <Content.list items={@content_items} />
    </div>
    """
  end
end
