defmodule Systems.Org.UserView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  @impl true
  def update(%{id: id, locale: _locale}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
    }
  end

  attr(:locale, :string)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-org", "user.title") %></Text.title2>
      </Area.content>
    </div>
    """
  end
end
