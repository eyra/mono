defmodule Next.Systems.Announcement.AdminViewBuilderTest do
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test

  import Ecto.Query

  alias Mica.Repo
  alias Next.Systems.Announcement

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
    recipient_ids = [Factories.insert!(:creator).id, Factories.insert!(:creator).id]

    older
    |> Ecto.Changeset.change(published_at: published_at, recipient_ids: recipient_ids)
    |> Repo.update!()

    assert %{allowed?: true, count: 2, items: [first, second]} = view_model(admin)

    assert %{
             id: newer_id,
             kind: "Release notes",
             title: "March release",
             priority: "High",
             published: "Not published",
             recipient_count: 0,
             buttons: [%{action: %{type: :send, event: "edit_announcement", item: edit_id}}]
           } = first

    assert newer_id == newer.id
    assert edit_id == newer.id

    assert %{
             title: "February release",
             priority: "Normal",
             recipient_count: 2,
             buttons: [%{action: %{type: :send, event: "edit_announcement", item: older_id}}]
           } = second

    assert older_id == older.id
    assert second.published == MicaWeb.UI.Timestamp.humanize(published_at)
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

  describe "audience" do
    setup do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      %{
        verified: Factories.insert!(:creator, %{email: "anna@example.org", verified_at: now}),
        unverified: Factories.insert!(:creator, %{email: "bram@example.org"})
      }
    end

    defp composing(user, assigns \\ %{}) do
      Announcement.AdminViewBuilder.view_model(
        nil,
        Map.merge(%{current_user: user, form: %{}}, assigns)
      )
    end

    test "is only built while composing", %{admin: admin} do
      assert %{audience: nil, published: nil} = view_model(admin)
    end

    test "is built while composing a saved draft", %{admin: admin} do
      draft = create!(admin, %{title: "Draft"})

      assert %{audience: %{recipient_count: 2}, published: nil} =
               composing(admin, %{announcement: draft})
    end

    test "is not built for a published announcement, which says what saving does", %{
      admin: admin
    } do
      {:ok, published} =
        admin
        |> create!(%{title: "Published"})
        |> Announcement.Public.publish_announcement([], nil, 2)

      assert %{audience: nil, published: %{text: text, notice: nil}} =
               composing(admin, %{announcement: published})

      assert text ==
               "This announcement is published. Saving shows your changes to its recipients " <>
                 "at once; it isn't sent again. Its priority and recipients can't change."

      Gettext.put_locale(MicaWeb.Gettext, "nl")
      on_exit(fn -> Gettext.put_locale(MicaWeb.Gettext, "en") end)

      assert %{published: %{text: text}} = composing(admin, %{announcement: published})

      assert text ==
               "Deze aankondiging is gepubliceerd. Na opslaan zien de ontvangers je wijzigingen " <>
                 "meteen; ze krijgen de aankondiging niet opnieuw. Prioriteit en ontvangers " <>
                 "kunnen niet meer veranderen."
    end

    test "says a save was refused because it changed since it was opened", %{admin: admin} do
      draft = create!(admin, %{title: "Draft"})
      {:ok, published} = Announcement.Public.publish_announcement(draft, [], nil, 2)

      en =
        "This announcement was changed in the meantime, so your changes were not saved. " <>
          "Cancel and open it again to see the latest version."

      assert %{audience: %{notice: ^en}} =
               composing(admin, %{announcement: draft, compose_notice: :changed_since_loaded})

      assert %{published: %{notice: ^en}} =
               composing(admin, %{announcement: published, compose_notice: :changed_since_loaded})

      Gettext.put_locale(MicaWeb.Gettext, "nl")
      on_exit(fn -> Gettext.put_locale(MicaWeb.Gettext, "en") end)

      assert %{published: %{notice: nl}} =
               composing(admin, %{announcement: published, compose_notice: :changed_since_loaded})

      assert nl ==
               "Deze aankondiging is intussen gewijzigd, dus je wijzigingen zijn niet " <>
                 "opgeslagen. Annuleer en open de aankondiging opnieuw om de nieuwste versie " <>
                 "te zien."
    end

    test "counts every creator with a confirmed account", %{admin: admin} do
      assert %{audience: %{recipient_count: 2, recipient_text: text}} = composing(admin)
      assert text == "2 creators will receive this announcement."
    end

    test "counts one creator in the singular", %{admin: admin} do
      assert %{audience: %{recipient_text: "1 creator will receive this announcement."}} =
               composing(admin, %{audience_filters: [:verified]})
    end

    test "search narrows the count", %{admin: admin} do
      assert %{audience: %{recipient_count: 1}} = composing(admin, %{audience_query: ["bram"]})
    end

    test "says when nobody matches", %{admin: admin} do
      assert %{audience: %{recipient_count: 0, recipient_text: text}} =
               composing(admin, %{audience_filters: [:verified, :unverified]})

      assert text == "No creators match these filters and search."
    end

    test "offers Verified and Unverified, not Creator, Affiliate or Pool", %{admin: admin} do
      assert %{audience: %{filter_labels: labels, creators_label: "Creators"}} =
               composing(admin, %{audience_filters: [:verified]})

      assert Enum.map(labels, &{&1.id, &1.active}) == [verified: true, unverified: false]
    end

    test "says that a high-priority announcement is also emailed", %{admin: admin} do
      assert %{audience: %{email_text: "Each recipient also gets an email."}} =
               composing(admin, %{priority: :high})
    end

    test "says that a normal announcement is not emailed", %{admin: admin} do
      assert %{audience: %{email_text: "No email is sent."}} = composing(admin)
    end

    test "is in Dutch for a Dutch admin", %{admin: admin} do
      Gettext.put_locale(MicaWeb.Gettext, "nl")
      on_exit(fn -> Gettext.put_locale(MicaWeb.Gettext, "en") end)

      assert %{
               audience: %{
                 recipient_text: "2 creators ontvangen deze aankondiging.",
                 email_text: "Elke ontvanger krijgt ook een e-mail."
               }
             } = composing(admin, %{priority: :high})
    end

    test "has no notice unless a save or publish was refused", %{admin: admin} do
      assert %{audience: %{notice: nil}} = composing(admin)
    end

    test "says the audience changed, with the current count", %{admin: admin} do
      assert %{
               audience: %{
                 notice: "The audience changed to 2 creators. Press Publish again to send it."
               }
             } = composing(admin, %{compose_notice: :audience_changed})
    end

    test "says the announcement was published in the meantime", %{admin: admin} do
      assert %{
               audience: %{
                 notice:
                   "This announcement was published in the meantime, so your changes were not saved."
               }
             } = composing(admin, %{compose_notice: :already_published})
    end

    test "the notices are in Dutch for a Dutch admin", %{admin: admin} do
      Gettext.put_locale(MicaWeb.Gettext, "nl")
      on_exit(fn -> Gettext.put_locale(MicaWeb.Gettext, "en") end)

      assert %{
               audience: %{
                 notice:
                   "De ontvangers zijn veranderd naar 2 creators. Druk nogmaals op Publiceren om te versturen."
               }
             } = composing(admin, %{compose_notice: :audience_changed})

      assert %{
               audience: %{
                 notice:
                   "Deze aankondiging is intussen gepubliceerd, dus je wijzigingen zijn niet opgeslagen."
               }
             } = composing(admin, %{compose_notice: :already_published})
    end
  end
end
