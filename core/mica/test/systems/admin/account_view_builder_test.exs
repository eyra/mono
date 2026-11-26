defmodule Systems.Admin.AccountViewBuilderTest do
  use Mica.DataCase
  use Mica.FeatureFlags.Test
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Admin.AccountViewBuilder
  alias Systems.Account

  describe "view_model/2" do
    test "builds correct view model structure" do
      vm = AccountViewBuilder.view_model(nil, %{})

      assert vm.title == dgettext("eyra-admin", "account.title")
      assert vm.search_placeholder == dgettext("eyra-admin", "search.placeholder")
      assert is_list(vm.filter_labels)
      assert is_list(vm.users)
      assert is_integer(vm.user_count)
    end

    test "user_count matches users list length" do
      vm = AccountViewBuilder.view_model(nil, %{})

      assert vm.user_count == length(vm.users)
    end

    test "has a filter per license and none for Verified" do
      set_feature_flag(:panl_post_launch, true)

      ids = Enum.map(AccountViewBuilder.view_model(nil, %{}).filter_labels, & &1.id)

      assert :publish in ids
      assert :pay_in in ids
      refute :verified in ids
      refute :unverified in ids
    end

    test "has no Pay-in filter without :panl_post_launch" do
      set_feature_flag(:panl_post_launch, false)

      ids = Enum.map(AccountViewBuilder.view_model(nil, %{}).filter_labels, & &1.id)

      assert :publish in ids
      refute :pay_in in ids
    end
  end

  describe "build_user_items/2" do
    setup do
      publisher = creator!()
      Factories.insert!(:license, %{user: publisher, license: :publish})

      payer = creator!()
      Factories.insert!(:license, %{user: payer, license: :pay_in})

      ended = creator!()

      Factories.insert!(:license, %{
        user: ended,
        license: :publish,
        valid_until: Date.add(Date.utc_today(), -1)
      })

      revoked = creator!()

      Factories.insert!(:license, %{
        user: revoked,
        license: :publish,
        revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      non_creator =
        Factories.insert!(:member, %{
          creator: false,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      %{
        publisher: publisher,
        payer: payer,
        ended: ended,
        revoked: revoked,
        non_creator: non_creator
      }
    end

    test "filters by :creator filter", %{publisher: publisher, non_creator: non_creator} do
      emails = emails([:creator])

      assert publisher.email in emails
      refute non_creator.email in emails
    end

    test "filters by :publish: only users whose Publish license counts today", ctx do
      emails = emails([:publish])

      assert ctx.publisher.email in emails
      refute ctx.payer.email in emails
      refute ctx.ended.email in emails
      refute ctx.revoked.email in emails
    end

    test "filters by :pay_in: only users whose Pay-in license counts today", ctx do
      emails = emails([:pay_in])

      assert ctx.payer.email in emails
      refute ctx.publisher.email in emails
    end

    test "filters by search query" do
      user = creator!()

      assert user.email in emails([], [user.email])
    end
  end

  describe "build_user_item/1" do
    test "builds correct item structure for a creator" do
      user = creator!()
      Factories.insert!(:license, %{user: user})

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      assert item.email == user.email
      assert item.name == user.displayname
      assert item.info == ""
      assert length(item.action_buttons) == 2

      licenses_button = Enum.find(item.action_buttons, &(&1.action.event == "licenses"))
      assert licenses_button.face.label == "Licenses"

      # Confirmed user should have deactivate button
      activate_button = Enum.find(item.action_buttons, &(&1.action.event == "deactivate_user"))
      assert activate_button != nil
      assert activate_button.face.label == "Deactivate"
    end

    test "builds correct item structure for non-creator" do
      user =
        Factories.insert!(:member, %{
          creator: false,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      # Non-creator should have make_creator button
      creator_button = Enum.find(item.action_buttons, &(&1.action.event == "make_creator"))
      assert creator_button != nil
      assert creator_button.face.label == "Make creator"
      refute Enum.find(item.action_buttons, &(&1.action.event == "licenses"))
    end

    test "builds correct item structure for unconfirmed user" do
      user = Factories.insert!(:member, %{creator: true, confirmed_at: nil})

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      # Unconfirmed user should have activate button
      activate_button = Enum.find(item.action_buttons, &(&1.action.event == "activate_user"))
      assert activate_button != nil
      assert activate_button.face.label == "Activate"
    end
  end

  describe "view_model/2 capping and bulk filters" do
    test "caps the rendered users list at 50, but user_count reflects the full match" do
      # Add a handful of creators so the unfiltered list is well above 50
      for _ <- 1..60 do
        Factories.insert!(:member, %{
          creator: true,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })
      end

      vm = AccountViewBuilder.view_model(nil, %{active_filters: [:creator], query: []})

      assert length(vm.users) == 50
      assert vm.user_count >= 60
    end

    test ":affiliate filter uses the bulk index and returns affiliate users only" do
      affiliate =
        Factories.insert!(:member, %{
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      Factories.insert!(:affiliate_user, %{user: affiliate, identifier: "affiliate_user_test"})

      non_affiliate =
        Factories.insert!(:member, %{
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      vm = AccountViewBuilder.view_model(nil, %{active_filters: [:affiliate], query: []})
      emails = Enum.map(vm.users, & &1.email)

      assert affiliate.email in emails
      refute non_affiliate.email in emails
    end
  end

  defp creator! do
    Factories.insert!(:member, %{
      creator: true,
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })
  end

  defp emails(filters, query \\ []) do
    filters
    |> AccountViewBuilder.build_user_items(query)
    |> Enum.map(& &1.email)
  end
end
