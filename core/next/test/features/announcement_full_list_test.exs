defmodule NextWeb.Features.AnnouncementFullListTest do
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Next.Systems.Announcement

  setup do
    set_feature_flag(:announcements, true)
    set_feature_flag(:password_sign_in, true)
    :ok
  end

  @tag :feature
  feature "the section action opens all announcements without marking them read", %{
    session: session
  } do
    password = "AnnouncementFeature123!"
    user = Factories.insert!(:creator, %{hashed_password: Bcrypt.hash_pwd_salt(password)})
    author = Factories.insert!(:admin)

    announcements =
      for day <- 1..8 do
        {:ok, announcement} =
          Announcement.Public.create_announcement(author, %{
            kind: :release_notes,
            title: "Full list announcement #{day}",
            summary: "Announcement summary",
            body: "<div>Read this announcement.</div>"
          })

        announcement =
          announcement
          |> Ecto.Changeset.change(
            published_at: DateTime.new!(Date.new!(2026, 10, day), ~T[09:00:00])
          )
          |> Repo.update!()

        %Announcement.RecipientModel{announcement_id: announcement.id, user_id: user.id}
        |> Announcement.RecipientModel.changeset(%{})
        |> Repo.insert!()

        announcement
      end

    oldest = hd(announcements)

    session =
      session
      |> sign_in(user, password)
      |> visit("/desktop")
      |> assert_connected("#desktop_section_announcements")
      |> assert_has(
        css("#desktop_section_announcements [data-testid=announcement-item]", count: 6)
      )
      |> refute_has(css("#announcement_item_#{oldest.id}"))
      |> execute_script(
        """
        const header = document.querySelector('#desktop_section_announcements [data-testid=section-header]');
        const action = header.querySelector('[data-testid=section-full-list]').getBoundingClientRect();
        const title = header.firstElementChild.getBoundingClientRect();
        return {gap: action.left - title.right, right: header.getBoundingClientRect().right - action.right};
        """,
        fn %{"gap" => gap, "right" => right} ->
          assert gap >= 0
          assert abs(right) < 2
        end
      )
      |> click(css("#desktop_section_announcements [data-testid=section-full-list]"))
      |> assert_connected("#announcements-list")
      |> assert_has(css("[data-testid=announcement-item]", count: 8))
      |> take_screenshot(name: "announcement-full-list")

    assert Announcement.Public.get_received(user, oldest.id).read_at == nil

    session
    |> click(css("#announcement_item_#{oldest.id}"))
    |> assert_connected("[data-testid=announcement-title]")
    |> assert_has(css("[data-testid=announcement-title]", text: oldest.title))

    assert %DateTime{} = Announcement.Public.get_received(user, oldest.id).read_at
  end
end
