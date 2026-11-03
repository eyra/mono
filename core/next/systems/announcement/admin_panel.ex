defmodule Next.Systems.Announcement.AdminPanel do
  @moduledoc "The Announcements tab on the Admin page, for system admins only."
  use Systems.Admin.Panel
  use Gettext, backend: MicaWeb.Gettext
  use Mica.FeatureFlags

  @impl true
  def id, do: :announcements

  @impl true
  def title, do: dgettext("eyra-announcement", "admin.title")

  @impl true
  def audience, do: :admin

  @impl true
  def enabled?, do: feature_enabled?(:announcements)

  @impl true
  def live_view, do: Next.Systems.Announcement.AdminView
end
