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
  # (`Next.Systems.Announcement.Public.get_received/2`), not by a role.
  def grants do
    quote do
      [
        {Next.Systems.Announcement.Page, [:member]}
      ]
    end
  end

  def feature_flags, do: [:announcements]
end
