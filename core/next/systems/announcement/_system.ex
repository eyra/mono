defmodule Systems.Announcement.System do
  @moduledoc """
  Announcements that system admins write for creators, such as release notes:
  the announcement, its cleaned rich-text body and the users who received it.

  Everything users see of announcements (the announcement page, the Admin tab,
  To-dos, email and the Desktop section) checks `feature_enabled?(:announcements)`
  first. The flag is off by default (`Next.SaaS.feature_flags/0`).
  """
  use Core.System

  def feature_flags, do: [:announcements]
end
