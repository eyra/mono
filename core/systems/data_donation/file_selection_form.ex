defmodule Systems.DataDonation.FileSelectionForm do
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
          <Title1>{dgettext("eyra-data-donation", "file_selection.welcome.title")}</Title1>
          <div class="text-bodylarge font-body">
            {dgettext("eyra-data-donation", "file_selection.welcome.description")}
          </div>

          <div class="mb-3 w-96">
            <label for="input-data-file" class="text-bodylarge font-body text-primary hover:text-grey1 underline focus:outline-none cursor-pointer">
              {dgettext("eyra-data-donation", "file_selection.file_upload.description")}
            </label>
            <input class="
            block w-full text-sm text-slate-500
            file:mr-4 file:py-2 file:px-4
            file:rounded-full file:border-0
            file:text-sm file:font-semibold
            file:bg-primary file:text-primary
            hover:file:text-grey1
            " type="file" id="input-data-file">
          </div>

          <label for="file-upload" class="text-bodylarge font-body text-primary hover:text-grey1 underline focus:outline-none cursor-pointer">

          </label>
          <input id="file-upload" type="file" data-role="file-input" hidden/>

          <p class="text-bodymedium text-grey2">
          {dgettext("eyra-data-donation", "file_selection.note")}
          </p>
        </SheetArea>
      </ContentArea>
    """
  end
end
