defmodule Systems.DataDonation.DataExtractionForm do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.Title1

  prop(script, :string, required: true)

  def update(%{id: id, props: %{script: script}}, socket) do
    {:ok, assign(socket, id: id, script: script)}
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <SheetArea>
          <Spacing value="XL" />
          <Title1>{dgettext("eyra-data-donation", "data_extraction.processing.title")}</Title1>
          <div class="sm:px-2 text-bodylarge sm:text-bodylarge font-body">
            {dgettext("eyra-data-donation", "data_extraction.processing.description")}
          </div>
          <div class="bg-grey6 p-4">
            <div class="loading-indicator">
              <div style="border-top-color: transparent"
                  class="
                  inline-block w-4 h-4 border-2 border-primary border-solid rounded-full animate-spin
                  "></div>
              <span class="text-grey2 font-body text-bodysmall px-2">
              {dgettext("eyra-data-donation", "data_extraction.processing.loading")}
              </span>
            </div>
            <code class="hidden">{@script}</code>
          </div>
          <p class="text-title6 text-warning">{dgettext("eyra-data-donation", "data_extraction.processing.warning")}</p>
          <p class="text-grey2 text-bodymedium">{dgettext("eyra-data-donation", "data_extraction.processing.note")}</p>
        </SheetArea>
      </ContentArea>
    """
  end
end
