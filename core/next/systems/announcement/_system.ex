defmodule Next.Systems.Announcement.System do
  @moduledoc """
  Announcements that system admins write for creators, such as release notes:
  the announcement, its rich-text body and the users who received it.

  Everything users see of announcements (the announcement page, the Admin tab,
  To-dos, email and the Desktop section) checks `feature_enabled?(:announcements)`
  first. The flag is off by default (`Next.SaaS.feature_flags/0`).
  """
  use Mica.System

  def routes do
    quote do
      require Next.Systems.Announcement.Routes
      Next.Systems.Announcement.Routes.routes()
    end
  end

  # Who may open an announcement is decided by its recipient rows
  # (`Next.Systems.Announcement.Public.get_received/2`), not by a role. The
  # compose page also checks for a system admin itself, as org admins have
  # the `:admin` role too.
  def grants do
    quote do
      [
        {Next.Systems.Announcement.Page, [:member]},
        {Next.Systems.Announcement.ComposePage, [:admin]}
      ]
    end
  end

  def signal_handlers, do: [Next.Systems.Announcement.Switch]

  def desktop_sections, do: [Next.Systems.Announcement.DesktopSection]

  def feature_flags, do: [:announcements]

  def admin_panels, do: [Next.Systems.Announcement.AdminPanel]
end
