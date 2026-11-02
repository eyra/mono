defmodule Systems.Announcement.DesktopSection do
  @moduledoc """
  The Announcements section on Desktop: the newest announcements the user
  received, read and unread, each opening the announcement page. Hidden while
  the `:announcements` flag is off and for users without announcements.

  It refreshes with Desktop: on `{:next_action, :cleared}` when an announcement
  is opened (`Systems.Desktop.Switch`) and on `{:announcement, :updated}`
  (`Systems.Announcement.Switch`).
  """
  use Systems.Desktop.Section
  use Core.FeatureFlags

  alias Frameworks.Pixel.Tag
  alias Systems.Announcement

  @limit 6

  @impl true
  def id, do: :announcements

  @impl true
  def title, do: dgettext("eyra-announcement", "desktop.title")

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
    <div class="flex flex-col gap-4">
      <%= for item <- @vm.items do %>
        <.link
          navigate={item.path}
          id={"announcement_item_#{item.id}"}
          data-testid="announcement-item"
          data-unread={to_string(item.unread?)}
        >
          <div class="p-4 md:p-6 rounded-md bg-grey6 flex flex-col gap-2">
            <div class="flex flex-row flex-wrap items-center gap-3">
              <div class="font-title6 text-title6 md:font-title5 md:text-title5 text-grey1 break-words">
                <%= item.title %>
              </div>
              <%= if item.unread? do %>
                <Tag.tag text={dgettext("eyra-announcement", "desktop.unread")} />
              <% end %>
            </div>
            <div class="text-bodysmall md:text-bodymedium font-body text-grey1 break-words">
              <%= item.summary %>
            </div>
            <div class="text-caption font-caption text-grey2">
              <%= item.published %>
            </div>
          </div>
        </.link>
      <% end %>
    </div>
    """
  end
end
