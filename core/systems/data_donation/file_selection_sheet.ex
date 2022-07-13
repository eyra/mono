defmodule Systems.DataDonation.FileSelectionSheet do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title1, BodyMedium, BodyLarge}

  prop(props, :map, required: true)

  data(script, :string)
  data(platform, :string)

  def update(%{id: id, props: %{script: script, platform: platform}}, socket) do
    {:ok, assign(socket, id: id, script: script, platform: platform)}
  end

  defp select_button() do
    label = dgettext("eyra-data-donation", "file_selection.file_upload.description")

    %{
      action: %{type: :click, code: "document.querySelector('#input-data-file').click()"},
      face: %{type: :primary, label: label}
    }
  end

  defp extract_button() do
    label = dgettext("eyra-data-donation", "extract.data.button")

    %{
      action: %{type: :click, code: ""},
      face: %{type: :primary, label: label}
    }
  end

  defp reset_button() do
    %{
      action: %{type: :click, code: ""},
      face: %{type: :icon, icon: :close, size: "h-14px w-14px"}
    }
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <SheetArea>
        <Title1>{dgettext("eyra-data-donation", "extract.data.title")}</Title1>

        <div class="select-file">
          <BodyLarge>
            {dgettext("eyra-data-donation", "file_selection.welcome.description", platform: @platform)}
          </BodyLarge>
          <Spacing value="M" />
          <div class="mb-3 w-96">
            <Wrap>
              <DynamicButton vm={select_button()} />
            </Wrap>
            <input class="hidden" type="file" id="input-data-file" accept="application/zip">
          </div>
          <Spacing value="M" />
        </div>

        <div class="hidden extract-data">
          <BodyLarge>
            {dgettext("eyra-data-donation", "selected.file.description")}
          </BodyLarge>
          <Spacing value="M" />
          <div class="flex flex-row h-14 px-5 items-center bg-grey5 rounded">
            <div class="flex-grow selected-filename text-label font-label text-grey1">filename</div>
            <div>
              <div class="reset-button">
                <DynamicButton vm={reset_button()} />
              </div>
            </div>
          </div>
          <Spacing value="M" />
          <div class="extract-data-button">
            <Wrap>
              <DynamicButton vm={extract_button()} />
            </Wrap>
          </div>
          <Spacing value="M" />
        </div>

        <div class="hidden data-extraction">
          <BodyLarge>
            {dgettext("eyra-data-donation", "file.extracton.description")}
          </BodyLarge>
          <Spacing value="M" />
          <div class="bg-grey6 p-4">
            <div class="loading-indicator flex flex-row items-center gap-4">
              <div
                style="border-top-color: transparent"
                class="inline-block w-4 h-4 border-2 border-primary border-solid rounded-full animate-spin"
              >
              </div>
              <BodyMedium>
                {dgettext("eyra-data-donation", "data_extraction.processing.loading")}
              </BodyMedium>
            </div>
            <code class="hidden">{@script}</code>
          </div>
          <Spacing value="M" />
        </div>

        <BodyMedium color="text-grey2">
          {dgettext("eyra-data-donation", "file_selection.note")}
        </BodyMedium>
      </SheetArea>
    </ContentArea>
    """
  end
end
