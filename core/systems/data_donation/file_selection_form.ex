defmodule Systems.DataDonation.FileSelectionForm do
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
          <Title1>{dgettext("eyra-data-donation", "file_selection.welcome.title")}</Title1>

          <div class="file-selection">
            <div class="text-bodylarge font-body">
              {dgettext("eyra-data-donation", "file_selection.welcome.description")}
            </div>
            <div class="selected-filename bg-grey5 p-2 text-grey1 hidden"></div>

            <div class="mb-3 w-96">
              <label for="input-data-file" class="text-bodylarge font-body text-primary hover:text-grey1 underline focus:outline-none cursor-pointer">
                {dgettext("eyra-data-donation", "file_selection.file_upload.description")}
              </label>
              <input class="hidden" type="file" id="input-data-file">
            </div>
            <p class="text-bodymedium text-grey2">
            {dgettext("eyra-data-donation", "file_selection.note")}
            </p>
            <button class="hidden extract-data-button">Extract data</button>
          </div>

          <div class="hidden data-extraction">
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
          </div>
        </SheetArea>
      </ContentArea>
    """
  end
end
