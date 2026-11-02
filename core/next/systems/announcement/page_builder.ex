defmodule Systems.Announcement.PageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.TrixPostProcessor
  alias Systems.Announcement

  # An update message brings the recipient without its announcement
  # (`Systems.Announcement.Switch`), so the latest text is read here.
  def view_model(
        %Announcement.RecipientModel{
          announcement: %Ecto.Association.NotLoaded{},
          announcement_id: announcement_id
        } = recipient,
        assigns
      ) do
    announcement = Announcement.Public.get_announcement!(announcement_id)
    view_model(%{recipient | announcement: announcement}, assigns)
  end

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

  defp published(published_at, timezone) do
    date = Announcement.Private.published_date(published_at, timezone)
    dgettext("eyra-announcement", "page.published", date: date)
  end
end
