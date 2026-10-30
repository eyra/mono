defmodule Systems.Announcement.PageBuilderTest do
  use ExUnit.Case, async: true

  alias Systems.Announcement

  @recipient %Announcement.RecipientModel{
    announcement: %Announcement.Model{
      title: "Release notes October",
      body: ~s|<div>See <a href="https://example.com">the docs</a></div>|,
      published_at: ~U[2026-10-28 09:00:00Z]
    }
  }

  @assigns %{timezone: "Europe/Amsterdam"}

  describe "view_model/2" do
    test "in English" do
      assert %{
               title: "Announcement",
               announcement_title: "Release notes October",
               published: "Published on 28 October 2026",
               body: ~s|<div>See <a href="https://example.com" target="_blank">the docs</a></div>|
             } =
               in_locale("en", fn -> Announcement.PageBuilder.view_model(@recipient, @assigns) end)
    end

    test "in Dutch" do
      assert %{title: "Aankondiging", published: "Gepubliceerd op 28 oktober 2026"} =
               in_locale("nl", fn -> Announcement.PageBuilder.view_model(@recipient, @assigns) end)
    end

    test "shows the publication day in the viewer's timezone" do
      # 00:30 on 1 November in Amsterdam (CET) is still 31 October in UTC.
      recipient = put_in(@recipient.announcement.published_at, ~U[2026-10-31 23:30:00Z])

      assert %{published: "Published on 1 November 2026"} =
               in_locale("en", fn -> Announcement.PageBuilder.view_model(recipient, @assigns) end)
    end
  end

  defp in_locale(locale, fun), do: Gettext.with_locale(CoreWeb.Gettext, locale, fun)
end
