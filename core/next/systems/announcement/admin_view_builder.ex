defmodule Systems.Announcement.AdminViewBuilder do
  @moduledoc """
  View model of the Announcements tab: every announcement, newest first, and
  the labels of the compose form. Only system admins with the `announcements`
  flag on get announcements (`allowed?`).
  """
  use Gettext, backend: CoreWeb.Gettext
  use Core.FeatureFlags

  alias CoreWeb.UI.Timestamp
  alias Systems.Admin
  alias Systems.Announcement

  def view_model(_model, assigns) do
    allowed? = feature_enabled?(:announcements) and admin?(Map.get(assigns, :current_user))
    timezone = Map.get(assigns, :timezone)
    announcements = if allowed?, do: Announcement.Public.list_announcements(), else: []
    recipient_counts = Announcement.Public.count_recipients(announcements)

    %{
      allowed?: allowed?,
      title: dgettext("eyra-announcement", "admin.title"),
      count: length(announcements),
      empty_text: dgettext("eyra-announcement", "admin.empty"),
      new_button: new_button(),
      head_cells: head_cells(),
      items: Enum.map(announcements, &to_item(&1, recipient_counts, timezone)),
      form: form_labels()
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

  # `buttons` holds the row's actions; publishing will add its button there.
  defp to_item(%Announcement.Model{id: id} = announcement, recipient_counts, timezone) do
    %{
      id: id,
      kind: kind_label(announcement.kind),
      title: announcement.title,
      priority: priority_label(announcement.priority),
      published: published_label(announcement.published_at, timezone),
      recipient_count: Map.get(recipient_counts, id, 0),
      buttons: []
    }
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
      cancel_button: dgettext("eyra-announcement", "form.cancel.button")
    }
  end

  def kind_label(:release_notes), do: dgettext("eyra-announcement", "kind.release_notes")

  def priority_label(:normal), do: dgettext("eyra-announcement", "priority.normal")
  def priority_label(:high), do: dgettext("eyra-announcement", "priority.high")
end
