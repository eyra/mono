defmodule Systems.DataDonation.SubmitDataForm do
  use CoreWeb.UI.LiveComponent
  alias Surface

  alias Frameworks.Pixel.Text.{Title2}

  def update(%{id: id}, socket) do
    {:ok, assign(socket, id: id)}
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <div class="flex flex-col items-center">
            <Title2>{dgettext("eyra-data-donation", "submit_data.title")}</Title2>
            <div class="sm:px-2 text-center text-bodymedium sm:text-bodylarge font-body">
              {dgettext("eyra-data-donation", "submit_data.description")}
            </div>

            <p class="extracted">...</p>

            <p>
            By pressing the donate button you agree to the following
            <a href= "https://eyra.co" class="text-bodymedium font-body text-primary hover:text-grey1 underline focus:outline-none" >
              terms and conditions
            </a>.
            </p>

            <form :on-submit={"donate", target: :live_view}>
              <input type="hidden" name="data" value="...">
              <button type="submit">Submit</button>
            </form>
         </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
