defmodule Next.Systems.Announcement.AdminViewBuilder do
  @moduledoc """
  View model of the Announcements tab: every announcement, newest first, the
  labels of the compose form and, while composing, the audience: who it
  reaches with the chosen filters and search, and whether they get an email.
  Only system admins with the `announcements` flag on get announcements
  (`allowed?`).

  Composing means a `form` is open, on `announcement` once it is saved. While
  composing an unpublished one, assigns read: `audience_filters` (from
  `Next.Systems.Announcement.Public.audience_filters/0`), `audience_query` (the
  search words), `priority` (the priority chosen in the form) and
  `compose_notice` (`:already_published`, `:changed_since_loaded`,
  `:audience_changed` or `:no_recipients` after a refused save or publish).
  A published one has
  no audience to choose, only `published`: what saving it does, and the
  notice of a refused save.
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
      items: Enum.map(announcements, &to_item(&1, audience_counts, timezone)),
      form: form_labels(),
      audience: audience(allowed? and composing(assigns) == :draft, assigns),
      published: published(allowed? and composing(assigns) == :published, assigns)
    }
  end

  defp admin?(nil), do: false
  defp admin?(user), do: Admin.Public.admin?(user)

  defp new_button do
    %{
      action: %{type: :send, event: "new_announcement"},
      face: %{type: :primary, label: dgettext("eyra-announcement", "admin.new.button")}
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
         %Announcement.Model{id: id, published_at: published_at} = announcement,
         audience_counts,
         timezone
       ) do
    %{
      id: id,
      kind: kind_label(announcement.kind),
      title: announcement.title,
      priority: priority_label(announcement.priority),
      published: published_label(published_at, timezone),
      recipient_count: Map.get(audience_counts, id, 0),
      buttons: buttons(announcement)
    }
  end

  defp buttons(%Announcement.Model{id: id}) do
    [
      %{
        action: %{type: :send, event: "edit_announcement", item: id},
        face: %{type: :plain, label: dgettext("eyra-announcement", "admin.edit.button")}
      }
    ]
  end

  defp published_label(nil, _timezone),
    do: dgettext("eyra-announcement", "admin.not.published")

  defp published_label(published_at, nil), do: Timestamp.humanize(published_at)

  defp published_label(published_at, timezone),
    do: published_at |> Timestamp.convert(timezone) |> Timestamp.humanize()

  defp form_labels do
    %{
      kind: dgettext("eyra-announcement", "form.kind.label"),
      title: dgettext("eyra-announcement", "form.title.label"),
      summary: dgettext("eyra-announcement", "form.summary.label"),
      body: dgettext("eyra-announcement", "form.body.label"),
      priority: dgettext("eyra-announcement", "form.priority.label"),
      kinds: Enum.map(Announcement.Model.kinds(), &{&1, kind_label(&1)}),
      priorities: Enum.map(Announcement.Model.priorities(), &{&1, priority_label(&1)}),
      save_button: dgettext("eyra-announcement", "form.save.button"),
      publish_button: dgettext("eyra-announcement", "form.publish.button"),
      cancel_button: dgettext("eyra-announcement", "form.cancel.button")
    }
  end

  defp composing(%{form: nil}), do: nil

  defp composing(%{form: _, announcement: %Announcement.Model{published_at: %DateTime{}}}),
    do: :published

  defp composing(%{form: _}), do: :draft
  defp composing(_assigns), do: nil

  defp published(false, _assigns), do: nil

  defp published(true, assigns) do
    %{
      text: dgettext("eyra-announcement", "form.published.notice"),
      notice: notice(Map.get(assigns, :compose_notice), 0)
    }
  end

  defp audience(false, _assigns), do: nil

  defp audience(true, assigns) do
    filters = Map.get(assigns, :audience_filters, [])
    query = Map.get(assigns, :audience_query)
    recipient_count = length(Announcement.Public.list_audience_ids(filters, query))

    %{
      label: dgettext("eyra-announcement", "form.audience.label"),
      creators_label: dgettext("eyra-announcement", "form.audience.creators"),
      filter_labels: Admin.UserFilters.labels(filters, Announcement.Public.audience_filters()),
      search_placeholder: dgettext("eyra-announcement", "form.audience.search.placeholder"),
      recipient_count: recipient_count,
      recipient_text: recipient_text(recipient_count),
      email_text: email_text(Map.get(assigns, :priority, :normal)),
      notice: notice(Map.get(assigns, :compose_notice), recipient_count)
    }
  end

  defp notice(nil, _recipient_count), do: nil

  defp notice(:already_published, _recipient_count),
    do: dgettext("eyra-announcement", "form.notice.already_published")

  defp notice(:changed_since_loaded, _recipient_count),
    do: dgettext("eyra-announcement", "form.notice.changed_since_loaded")

  defp notice(:no_recipients, _recipient_count),
    do: dgettext("eyra-announcement", "form.notice.no_recipients")

  defp notice(:audience_changed, recipient_count) do
    dngettext(
      "eyra-announcement",
      "form.notice.audience_changed.one",
      "form.notice.audience_changed.other",
      recipient_count,
      count: recipient_count
    )
  end

  defp recipient_text(0), do: dgettext("eyra-announcement", "form.audience.none")

  defp recipient_text(count) do
    dngettext(
      "eyra-announcement",
      "form.audience.count.one",
      "form.audience.count.other",
      count,
      count: count
    )
  end

  defp email_text(:high), do: dgettext("eyra-announcement", "form.email.high")
  defp email_text(_priority), do: dgettext("eyra-announcement", "form.email.normal")

  def kind_label(:release_notes), do: dgettext("eyra-announcement", "kind.release_notes")

  def priority_label(:normal), do: dgettext("eyra-announcement", "priority.normal")
  def priority_label(:high), do: dgettext("eyra-announcement", "priority.high")
end
