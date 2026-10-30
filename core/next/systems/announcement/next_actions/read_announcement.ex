defmodule Systems.Announcement.NextActions.ReadAnnouncement do
  @moduledoc """
  The To-do of one unread announcement. There is one per recipient, keyed by
  the announcement (`key/1`). Title and summary are read from the announcement
  when the To-do is shown, so edits show at once. Opening the announcement
  page clears it (`Systems.Announcement.Public.mark_read/1`).
  """
  @behaviour Systems.NextAction.ViewModel
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Announcement

  @doc "The next-action key of the announcement with `announcement_id`."
  def key(announcement_id), do: to_string(announcement_id)

  @doc "The next-action params of the announcement with `announcement_id`."
  def params(announcement_id), do: %{"announcement_id" => announcement_id}

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"announcement_id" => announcement_id}) do
    %{title: title, summary: summary} = Announcement.Public.get_announcement!(announcement_id)

    %{
      title: title,
      description: summary,
      cta_label: dgettext("eyra-announcement", "next_action.cta"),
      cta_action: %{type: :redirect, to: Announcement.Private.page_path(announcement_id)}
    }
  end
end
