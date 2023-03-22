defmodule Systems.Org.UserView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title2

  prop(props, :map)

  def update(%{id: id, props: %{locale: _locale}}, socket) do
    {
      :ok,
      socket
      |> assign(id: id)
    }
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <Title2>{dgettext("eyra-org", "user.title")}</Title2>
    </ContentArea>
    """
  end
end
