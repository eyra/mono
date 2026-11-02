defmodule Systems.Announcement.Private do
  alias CoreWeb.UI.Timestamp

  @doc """
  The path of the announcement page (`Systems.Announcement.Routes`). A plain
  path, not `~p`: other SaaS builds compile this system without its routes.
  """
  def page_path(announcement_id), do: "/announcement/#{announcement_id}"

  @doc "The full address of the announcement page, for use outside Next such as in email."
  def page_url(announcement_id), do: CoreWeb.Endpoint.url() <> page_path(announcement_id)

  @doc "The publication date in `timezone` and the current locale, such as \"28 October 2026\"."
  def published_date(%DateTime{} = published_at, timezone) do
    published_at
    |> Timestamp.convert(timezone)
    |> Timex.lformat!("{D} {Mfull} {YYYY}", Gettext.get_locale(CoreWeb.Gettext))
  end
end
