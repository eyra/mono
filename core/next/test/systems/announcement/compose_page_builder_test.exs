defmodule Next.Systems.Announcement.ComposePageBuilderTest do
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test

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

  defp new_announcement, do: %Announcement.Model{kind: :release_notes, priority: :normal}

  defp composing(user, assigns \\ %{}) do
    announcement = Map.get(assigns, :announcement, new_announcement())

    Announcement.ComposePageBuilder.view_model(
      announcement,
      Map.put(assigns, :current_user, user)
    )
  end

  test "says whether it is a new announcement", %{admin: admin} do
    assert %{heading: "New announcement"} = composing(admin)

    assert %{heading: "Edit announcement"} =
             composing(admin, %{announcement: create!(admin, %{title: "Draft"})})
  end

  test "builds the audience before the page opened the announcement", %{admin: admin} do
    assert %{audience: %{recipient_count: _}, published: nil} =
             Announcement.ComposePageBuilder.view_model(new_announcement(), %{current_user: admin})
  end

  test "builds no audience and no published notice when the flag is off", %{admin: admin} do
    published =
      admin
      |> create!(%{title: "Published"})
      |> Ecto.Changeset.change(published_at: DateTime.utc_now() |> DateTime.truncate(:second))
      |> Mica.Repo.update!()

    set_feature_flag(:announcements, false)

    assert %{allowed?: false, audience: nil, published: nil} = composing(admin)

    assert %{allowed?: false, audience: nil, published: nil} =
             composing(admin, %{announcement: published})
  end

  test "builds no audience for a user who is not a system admin" do
    for user <- [Factories.insert!(:creator), Factories.insert!(:member), nil] do
      assert %{allowed?: false, audience: nil, published: nil} = composing(user)
    end
  end

  test "offers every kind and priority in the form", %{admin: admin} do
    assert %{form: %{kinds: [release_notes: "Release notes"], priorities: priorities}} =
             composing(admin)

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

    test "is built for a new announcement", %{admin: admin} do
      assert %{audience: %{recipient_count: 2}, published: nil} = composing(admin)
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
