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
        recipients -> %{items: Announcement.Cards.items(recipients, assigns)}
      end
    end
  end

  @impl true
  def full_list(_vm) do
    %{
      label: dgettext("eyra-announcement", "desktop.view_all"),
      to: Announcement.Private.list_path()
    }
  end

  @impl true
  def full_view_model(user, assigns) do
    if feature_enabled?(:announcements) do
      %{items: Announcement.Public.list_received(user) |> Announcement.Cards.items(assigns)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @vm.items == [] do %>
      <Text.body_medium><%= dgettext("eyra-announcement", "list.empty") %></Text.body_medium>
    <% else %>
      <Announcement.Cards.list items={@vm.items} />
    <% end %>
    """
  end
end
