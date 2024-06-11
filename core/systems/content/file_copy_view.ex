defmodule Systems.Content.FileCopyView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Annotation

  alias Systems.Content

  @impl true
  def update(%{id: id, file: file, annotation: annotation}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        file: file,
        annotation: annotation
      )
      |> update_url()
    }
  end

  defp update_url(%{assigns: %{file: nil}} = socket) do
    assign(socket, url: nil)
  end

  defp update_url(
         %{
           assigns: %{
             file: %Content.FileModel{ref: ref}
           }
         } = socket
       ) do
    assign(socket, url: ref)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Panel.flat bg_color="bg-grey1">
        <%= if @url do %>
          <Annotation.view annotation={@annotation} />
          <div class="flex flex-row gap-6 items-center">
            <div class="flex-wrap">
              <Text.body_large color="text-white"><span class="break-all"><%= @url %></span></Text.body_large>
            </div>
            <div class="flex-wrap flex-shrink-0 mt-1">
              <div id="copy-assignment-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@url}>
                <Button.Face.label_icon
                  label={dgettext("eyra-ui", "copy.clipboard.button")}
                  icon={:clipboard_tertiary}
                  text_color="text-tertiary"
                />
              </div>
            </div>
          </div>
        <% end %>
      </Panel.flat>
    </div>
    """
  end
end
