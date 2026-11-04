defmodule Next.Systems.Announcement.Cards do
  @moduledoc "Announcement cards shared by the Desktop preview and the full list."
  use MicaWeb, :html

  alias Frameworks.Pixel.Card
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Text
  alias Next.Systems.Announcement

  def items(recipients, assigns), do: Enum.map(recipients, &item(&1, assigns))

  defp item(
         %Announcement.RecipientModel{
           read_at: read_at,
           announcement: %Announcement.Model{
             id: id,
             title: title,
             summary: summary,
             published_at: published_at
           }
         },
         assigns
       ) do
    %{
      id: id,
      title: title,
      summary: summary,
      published: Announcement.Private.published_date(published_at, timezone(assigns)),
      unread?: read_at == nil,
      path: Announcement.Private.page_path(id)
    }
  end

  defp timezone(assigns), do: Map.get(assigns, :timezone, "Etc/UTC")

  attr(:items, :list, required: true)

  def list(assigns) do
    ~H"""
    <Grid.dynamic>
      <%= for item <- @items do %>
        <.link
          navigate={item.path}
          id={"announcement_item_#{item.id}"}
          class="block h-full"
          data-testid="announcement-item"
          data-unread={to_string(item.unread?)}
        >
          <Card.normal bg_color="bg-grey5">
            <:title>
              <div class="text-title5 font-title5 lg:text-title3 lg:font-title3 text-grey1 break-words">
                <%= item.title %>
              </div>
            </:title>
            <div class="flex flex-col gap-4 mt-4">
              <%= if item.unread? do %>
                <div>
                  <Tag.tag text={dgettext("eyra-announcement", "desktop.unread")} />
                </div>
              <% end %>
              <Text.body_medium color="text-grey1">
                <span class="break-words"><%= item.summary %></span>
              </Text.body_medium>
              <Text.sub_head color="text-grey2"><%= item.published %></Text.sub_head>
            </div>
          </Card.normal>
        </.link>
      <% end %>
    </Grid.dynamic>
    """
  end
end
