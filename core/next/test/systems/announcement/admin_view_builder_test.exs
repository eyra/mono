defmodule Systems.Announcement.AdminViewBuilderTest do
  use Core.DataCase, async: false
  use Core.FeatureFlags.Test

  import Ecto.Query

  alias Core.Repo
  alias Systems.Announcement

  @attrs %{
    kind: :release_notes,
    summary: "What changed",
    body: "<div>New features</div>",
    priority: :normal
  }

  setup do
    set_feature_flag(:announcements, true)
    %{admin: Factories.insert!(:admin)}
  end

  defp create!(author, attrs) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(author, Map.merge(@attrs, attrs))

    announcement
  end

  defp view_model(user), do: Announcement.AdminViewBuilder.view_model(nil, %{current_user: user})

  test "lists every announcement newest first, with its fields", %{admin: admin} do
    older = create!(admin, %{title: "February release"})

    Repo.update_all(
      from(a in Announcement.Model, where: a.id == ^older.id),
      set: [inserted_at: ~N[2026-02-01 10:00:00]]
    )

    newer = create!(admin, %{title: "March release", priority: :high})

    published_at = ~U[2026-02-02 12:00:00Z]
    older |> Ecto.Changeset.change(published_at: published_at) |> Repo.update!()

    for user <- [Factories.insert!(:creator), Factories.insert!(:creator)] do
      Repo.insert!(%Announcement.RecipientModel{announcement_id: older.id, user_id: user.id})
    end

    assert %{allowed?: true, count: 2, items: [first, second]} = view_model(admin)

    assert %{
             id: newer_id,
             kind: "Release notes",
             title: "March release",
             priority: "High",
             published: "Not published",
             recipient_count: 0,
             buttons: []
           } = first

    assert newer_id == newer.id

    assert %{
             title: "February release",
             priority: "Normal",
             recipient_count: 2
           } = second

    assert second.published == CoreWeb.UI.Timestamp.humanize(published_at)
  end

  test "has no announcements for a user who is not a system admin", %{admin: admin} do
    create!(admin, %{title: "March release"})

    for user <- [Factories.insert!(:creator), Factories.insert!(:member), nil] do
      assert %{allowed?: false, count: 0, items: []} = view_model(user)
    end
  end

  test "has no announcements when the flag is off", %{admin: admin} do
    create!(admin, %{title: "March release"})
    set_feature_flag(:announcements, false)

    assert %{allowed?: false, items: []} = view_model(admin)
  end

  test "offers every kind and priority in the form", %{admin: admin} do
    assert %{form: %{kinds: [release_notes: "Release notes"], priorities: priorities}} =
             view_model(admin)

    assert priorities == [normal: "Normal", high: "High"]
  end
end
