defmodule Systems.DataDonation.WelcomeForm do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title1

  def update(%{id: id}, socket) do
    {:ok, assign(socket, id: id)}
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <Title1>{dgettext("eyra-data-donation", "welcome.title")}</Title1>
          <div class="text-bodylarge font-body">
            {dgettext("eyra-data-donation", "welcome.description")}
          </div>

        </SheetArea>
      </ContentArea>
    """
  end
end
