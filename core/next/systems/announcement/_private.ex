defmodule Next.Systems.Announcement.Private do
  alias MicaWeb.UI.Timestamp

  @doc """
  The path of the announcement page (`Next.Systems.Announcement.Routes`). A plain
  path, not `~p`: other SaaS builds compile this system without its routes.
  """
  def page_path(announcement_id), do: "/announcement/#{announcement_id}"

  @doc "The publication date in `timezone` and the current locale, such as \"28 October 2026\"."
  def published_date(%DateTime{} = published_at, timezone) do
    published_at
    |> Timestamp.convert(timezone)
    |> Timex.lformat!("{D} {Mfull} {YYYY}", Gettext.get_locale(MicaWeb.Gettext))
  end
end
