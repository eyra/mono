defmodule Systems.Assignment.ParticipantsView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Annotation

  @impl true
  def update(%{id: id, assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(id: id, assignment: assignment)
      |> update_title()
      |> update_annotation()
      |> update_url()
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "invite.panel.title")
    assign(socket, title: title)
  end

  defp update_annotation(socket) do
    annotation = dgettext("eyra-assignment", "invite.panel.annotation")
    assign(socket, annotation: annotation)
  end

  defp update_url(%{assigns: %{assignment: %{id: id}}} = socket) do
    path = ~p"/assignment/#{id}/invite"
    url = get_base_url() <> path
    assign(socket, url: url)
  end

  defp get_base_url do
    Application.get_env(:core, :base_url)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-assignment", "participants.title") %></Text.title2>
          <.spacing value="L" />

          <Panel.flat bg_color="bg-grey1">
            <:title>
              <div class="text-title3 font-title3 text-white">
                <%= @title %>
              </div>
            </:title>
            <.spacing value="S" />
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
          </Panel.flat>
        </Area.content>
      </div>
    """
  end
end
