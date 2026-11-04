defmodule Next.Systems.Announcement.Private do
  use Gettext, backend: MicaWeb.Gettext

  alias MicaWeb.UI.Timestamp

  @doc """
  The path of the announcement page (`Next.Systems.Announcement.Routes`). A plain
  path, not `~p`: other SaaS builds compile this system without its routes.
  """
  def page_path(announcement_id), do: "/announcement/#{announcement_id}"

  @doc "The full address of the announcement page, for use outside Next such as in email."
  def page_url(announcement_id), do: MicaWeb.Endpoint.url() <> page_path(announcement_id)

  @doc """
  The path of the page to compose a new announcement (`:new`) or to open one, a
  plain path like `page_path/1`.
  """
  def compose_path(:new), do: "/admin/announcement/new"
  def compose_path(announcement_id), do: "/admin/announcement/#{announcement_id}"

  @doc "The publication date in `timezone` and the current locale, such as \"28 October 2026\"."
  def published_date(%DateTime{} = published_at, timezone) do
    published_at
    |> Timestamp.convert(timezone)
    |> Timex.lformat!("{D} {Mfull} {YYYY}", Gettext.get_locale(MicaWeb.Gettext))
  end

  def kind_label(:release_notes), do: dgettext("eyra-announcement", "kind.release_notes")

  def priority_label(:normal), do: dgettext("eyra-announcement", "priority.normal")
  def priority_label(:high), do: dgettext("eyra-announcement", "priority.high")
end
