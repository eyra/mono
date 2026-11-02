defmodule Next.Systems.Announcement.PageBuilder do
  use Gettext, backend: MicaWeb.Gettext

  alias MicaWeb.UI.Timestamp
  alias Frameworks.Pixel.TrixPostProcessor
  alias Next.Systems.Announcement

  def view_model(
        %Announcement.RecipientModel{
          announcement: %Announcement.Model{
            title: title,
            body: body,
            published_at: published_at
          }
        },
        %{timezone: timezone}
      ) do
    %{
      title: dgettext("eyra-announcement", "page.title"),
      active_menu_item: :desktop,
      announcement_title: title,
      published: published(published_at, timezone),
      body: TrixPostProcessor.add_target_blank(body)
    }
  end

  defp published(%DateTime{} = published_at, timezone) do
    date =
      published_at
      |> Timestamp.convert(timezone)
      |> Timex.lformat!("{D} {Mfull} {YYYY}", Gettext.get_locale(MicaWeb.Gettext))

    dgettext("eyra-announcement", "page.published", date: date)
  end
end
