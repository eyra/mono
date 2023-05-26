defmodule Systems.DataDonation.FileSelectionSheet do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  @impl true
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <Text.title1><%= dgettext("eyra-data-donation", "extract.data.title") %></Text.title1>

        <div class="select-file">
          <Text.body_large>
            <%= dgettext("eyra-data-donation", "file_selection.welcome.description", platform: @platform) %>
          </Text.body_large>
          <.spacing value="M" />
          <div class="mb-3 w-96">
            <.wrap>
              <Button.dynamic {select_button()} />
            </.wrap>
            <input class="hidden" type="file" id="input-data-file" accept="application/zip, text/plain">
          </div>
          <.spacing value="M" />
        </div>

        <div class="hidden extract-data">
          <Text.body_large>
            <%= dgettext("eyra-data-donation", "selected.file.description") %>
          </Text.body_large>
          <.spacing value="M" />
          <div class="flex flex-row h-14 px-5 items-center bg-grey5 rounded">
            <div class="flex-grow selected-filename text-label font-label text-grey1">filename</div>
            <div>
              <div class="reset-button">
                <Button.dynamic {reset_button()} />
              </div>
            </div>
          </div>
          <.spacing value="M" />
          <div class="extract-data-button">
            <.wrap>
              <Button.dynamic {extract_button()} />
            </.wrap>
          </div>
          <.spacing value="M" />
        </div>

        <div class="hidden data-extraction">
          <Text.body_large>
            <%= dgettext("eyra-data-donation", "file.extracton.description") %>
          </Text.body_large>
          <.spacing value="M" />
          <div class="bg-grey6 p-4">
            <div class="loading-indicator flex flex-row items-center gap-4">
              <div
                style="border-top-color: transparent"
                class="inline-block w-4 h-4 border-2 border-primary border-solid rounded-full animate-spin"
              >
              </div>
              <Text.body_medium>
                <%= dgettext("eyra-data-donation", "data_extraction.processing.loading") %>
              </Text.body_medium>
            </div>
            <code class="hidden"><%= @script %></code>
          </div>
          <.spacing value="M" />
        </div>

        <Text.body_medium color="text-grey2">
          <%= dgettext("eyra-data-donation", "file_selection.note") %>
        </Text.body_medium>
      </Area.sheet>
      </Area.content>
    </div>
    """
  end
end
