defmodule Next.Systems.Announcement.ComposePageBuilder do
  @moduledoc """
  View model of the page to compose an announcement
  (`Next.Systems.Announcement.ComposePage`): the labels of the form and, for an
  unpublished one, the audience: who it reaches with the chosen filters and
  search, and whether they get an email.

  Assigns read: `announcement` (the one being composed; the page's model until
  the page has opened it), `audience_filters` (from
  `Next.Systems.Announcement.Public.audience_filters/0`), `audience_query` (the
  search words), `priority` (the priority chosen in the form) and
  `compose_notice` (`:already_published`, `:changed_since_loaded`,
  `:audience_changed` or `:no_recipients` after a refused save or publish).
  A published one has no audience to choose, only `published`: what saving it
  does, and the notice of a refused save.

  Only system admins with the `announcements` flag on (`allowed?`) get the
  audience or `published`.
  """
  use Gettext, backend: MicaWeb.Gettext
  use Mica.FeatureFlags

  alias Next.Systems.Announcement
  alias Systems.Admin

  def view_model(%Announcement.Model{} = model, assigns) do
    announcement = Map.get(assigns, :announcement, model)
    allowed? = feature_enabled?(:announcements) and admin?(Map.get(assigns, :current_user))

    %{
      allowed?: allowed?,
      title: dgettext("eyra-announcement", "admin.title"),
      active_menu_item: :admin,
      heading: heading(announcement),
      form: form_labels(),
      audience: audience(allowed? and not published?(announcement), assigns),
      published: published(allowed? and published?(announcement), assigns)
    }
  end

  defp admin?(nil), do: false
  defp admin?(user), do: Admin.Public.admin?(user)

  defp heading(%Announcement.Model{id: nil}), do: dgettext("eyra-announcement", "compose.new")
  defp heading(_announcement), do: dgettext("eyra-announcement", "compose.edit")

  defp published?(%Announcement.Model{published_at: %DateTime{}}), do: true
  defp published?(_announcement), do: false

  defp form_labels do
    %{
      kind: dgettext("eyra-announcement", "form.kind.label"),
      title: dgettext("eyra-announcement", "form.title.label"),
      summary: dgettext("eyra-announcement", "form.summary.label"),
      body: dgettext("eyra-announcement", "form.body.label"),
      priority: dgettext("eyra-announcement", "form.priority.label"),
      kinds: Enum.map(Announcement.Model.kinds(), &{&1, Announcement.Private.kind_label(&1)}),
      priorities:
        Enum.map(Announcement.Model.priorities(), &{&1, Announcement.Private.priority_label(&1)}),
      save_button: dgettext("eyra-announcement", "form.save.button"),
      publish_button: dgettext("eyra-announcement", "form.publish.button"),
      cancel_button: dgettext("eyra-announcement", "form.cancel.button")
    }
  end

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
end
