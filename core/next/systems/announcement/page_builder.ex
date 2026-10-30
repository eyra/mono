defmodule Systems.Announcement.PageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.TrixPostProcessor
  alias Systems.Announcement

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
      |> Timex.Timezone.convert(timezone)
      |> Timex.lformat!("{D} {Mfull} {YYYY}", Gettext.get_locale(CoreWeb.Gettext))

    dgettext("eyra-announcement", "page.published", date: date)
  end
end
