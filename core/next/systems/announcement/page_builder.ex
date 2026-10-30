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
        _assigns
      ) do
    %{
      title: dgettext("eyra-announcement", "page.title"),
      active_menu_item: :desktop,
      announcement_title: title,
      published: published(published_at),
      body: TrixPostProcessor.add_target_blank(body)
    }
  end

  defp published(nil), do: nil

  defp published(%DateTime{} = published_at) do
    date = Timex.lformat!(published_at, "{D} {Mfull} {YYYY}", Gettext.get_locale(CoreWeb.Gettext))

    dgettext("eyra-announcement", "page.published", date: date)
  end
end
