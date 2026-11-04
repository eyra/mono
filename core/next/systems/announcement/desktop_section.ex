defmodule Next.Systems.Announcement.DesktopSection do
  @moduledoc """
  The Announcements section on Desktop, above Recent items: the newest
  announcements the user received, read and unread, as cards that each open
  the announcement page. Hidden while
  the `:announcements` flag is off and for users without announcements.

  It refreshes with Desktop: on `{:next_action, :cleared}` when an announcement
  is opened (`Systems.Desktop.Switch`) and on `{:announcement, :updated}`
  (`Next.Systems.Announcement.Switch`).
  """
  use Systems.Desktop.Section
  use Mica.FeatureFlags

  alias Frameworks.Pixel.Card
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Text
  alias Next.Systems.Announcement

  @limit 6

  @impl true
  def id, do: :announcements

  @impl true
  def title, do: dgettext("eyra-announcement", "desktop.title")

  @impl true
  def placement, do: :before_recent_items

  @impl true
  def view_model(user, assigns) do
    if feature_enabled?(:announcements) do
      case Announcement.Public.list_received(user, limit: @limit) do
        [] -> nil
        recipients -> %{items: Enum.map(recipients, &item(&1, assigns))}
      end
    end
  end

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

  @impl true
  def render(assigns) do
    ~H"""
    <Grid.dynamic>
      <%= for item <- @vm.items do %>
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
