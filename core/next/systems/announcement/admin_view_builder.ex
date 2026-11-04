defmodule Next.Systems.Announcement.AdminViewBuilder do
  @moduledoc """
  View model of the Announcements tab: every announcement, newest first, each
  with the path of the page that opens it, and the link to compose a new one
  (`Next.Systems.Announcement.ComposePage`). Only system admins with the
  `announcements` flag on get announcements (`allowed?`).
  """
  use Gettext, backend: MicaWeb.Gettext
  use Mica.FeatureFlags

  alias MicaWeb.UI.Timestamp
  alias Systems.Admin
  alias Next.Systems.Announcement

  def view_model(_model, assigns) do
    allowed? = feature_enabled?(:announcements) and admin?(Map.get(assigns, :current_user))
    timezone = Map.get(assigns, :timezone)
    announcements = if allowed?, do: Announcement.Public.list_announcements(), else: []
    audience_counts = Announcement.Public.count_audiences(announcements)

    %{
      allowed?: allowed?,
      title: dgettext("eyra-announcement", "admin.title"),
      count: length(announcements),
      empty_text: dgettext("eyra-announcement", "admin.empty"),
      new_button: new_button(),
      head_cells: head_cells(),
      items: Enum.map(announcements, &to_item(&1, audience_counts, timezone))
    }
  end

  defp admin?(nil), do: false
  defp admin?(user), do: Admin.Public.admin?(user)

  defp new_button do
    %{
      action: %{type: :redirect, to: Announcement.Private.compose_path(:new)},
      face: %{
        type: :plain,
        label: dgettext("eyra-announcement", "admin.new.button"),
        icon: :forward
      }
    }
  end

  defp head_cells do
    [
      dgettext("eyra-announcement", "admin.column.kind"),
      dgettext("eyra-announcement", "admin.column.title"),
      dgettext("eyra-announcement", "admin.column.priority"),
      dgettext("eyra-announcement", "admin.column.published"),
      dgettext("eyra-announcement", "admin.column.recipients")
    ]
  end

  # The recipient count of a published announcement is its audience, fixed at
  # publication; its recipient rows follow in a job.
  defp to_item(
         %Announcement.Model{
           id: id,
           kind: kind,
           title: title,
           priority: priority,
           published_at: published_at
         },
         audience_counts,
         timezone
       ) do
    %{
      id: id,
      path: Announcement.Private.compose_path(id),
      kind: Announcement.Private.kind_label(kind),
      title: title,
      priority: Announcement.Private.priority_label(priority),
      published: published_label(published_at, timezone),
      recipient_count: Map.get(audience_counts, id, 0)
    }
  end

  defp published_label(nil, _timezone),
    do: dgettext("eyra-announcement", "admin.not.published")

  defp published_label(published_at, nil), do: Timestamp.humanize(published_at)

  defp published_label(published_at, timezone),
    do: published_at |> Timestamp.convert(timezone) |> Timestamp.humanize()
end
