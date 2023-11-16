defmodule Systems.Assignment.ConnectionViewPanel do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Annotation

  alias Systems.{
    Assignment
  }

  @impl true
  def update(%{event: :disconnect}, %{assigns: %{assignment: assignment}} = socket) do
    changeset = Assignment.Model.changeset(assignment, %{external_panel: nil})

    {
      :ok,
      socket
      |> save(changeset)
    }
  end

  @impl true
  def update(%{id: id, assignment: assignment, uri_origin: uri_origin}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        uri_origin: uri_origin
      )
      |> update_annotation()
      |> update_url()
    }
  end

  defp update_annotation(%{assigns: %{assignment: %{external_panel: nil}}} = socket) do
    assign(socket, annotation: nil)
  end

  defp update_annotation(%{assigns: %{assignment: %{external_panel: external_panel}}} = socket) do
    annotation =
      case external_panel do
        :liss -> dgettext("eyra-assignment", "panel.liss.connection.annotation")
        :ioresearch -> dgettext("eyra-assignment", "panel.ioresearch.connection.annotation")
        :generic -> dgettext("eyra-assignment", "panel.generic.connection.annotation")
      end

    assign(socket, annotation: annotation)
  end

  defp update_url(%{assigns: %{assignment: %{external_panel: nil}}} = socket) do
    assign(socket, url: nil)
  end

  defp update_url(
         %{
           assigns: %{
             assignment: %{id: id, external_panel: external_panel},
             uri_origin: uri_origin
           }
         } = socket
       ) do
    relative_url =
      case external_panel do
        :liss -> "/assignment/#{id}/liss"
        :ioresearch -> "/assignment/#{id}/ioresearch?participant=<id>&language=nl"
        :generic -> "/assignment/#{id}/participate?participant=<id>&language=nl"
      end

    assign(socket, url: uri_origin <> relative_url)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @annotation do %>
        <Annotation.view annotation={@annotation} />
      <% end %>
      <%= if @url do %>
        <.spacing value="S" />
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
    </div>
    """
  end
end
