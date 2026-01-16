defmodule Systems.Admin.AccountViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

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
  end

  describe "build_user_items/2" do
    setup do
      # Create test users with different states
      creator_verified =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      creator_unverified =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: nil,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      non_creator =
        Factories.insert!(:member, %{
          creator: false,
          verified_at: nil,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      %{
        creator_verified: creator_verified,
        creator_unverified: creator_unverified,
        non_creator: non_creator
      }
    end

    test "filters by :creator filter", %{
      creator_verified: creator_verified,
      non_creator: non_creator
    } do
      items = AccountViewBuilder.build_user_items([:creator], [])

      emails = Enum.map(items, & &1.email)

      assert creator_verified.email in emails
      refute non_creator.email in emails
    end

    test "filters by search query" do
      user =
        Factories.insert!(:member, %{
          creator: true,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      # Search by email
      items = AccountViewBuilder.build_user_items([], [user.email])

      emails = Enum.map(items, & &1.email)
      assert user.email in emails
    end
  end

  describe "build_user_item/1" do
    test "builds correct item structure for verified creator" do
      user =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      assert item.email == user.email
      assert item.name == user.displayname
      assert is_binary(item.info)
      assert item.info =~ "Verified"
      assert length(item.action_buttons) == 2

      # Verified creator should have unverify button
      verify_button = Enum.find(item.action_buttons, &(&1.action.event == "unverify_creator"))
      assert verify_button != nil
      assert verify_button.face.label == "Unverify"

      # Confirmed user should have deactivate button
      activate_button = Enum.find(item.action_buttons, &(&1.action.event == "deactivate_user"))
      assert activate_button != nil
      assert activate_button.face.label == "Deactivate"
    end

    test "builds correct item structure for unverified creator" do
      user =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: nil,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      assert item.info == ""

      # Unverified creator should have verify button
      verify_button = Enum.find(item.action_buttons, &(&1.action.event == "verify_creator"))
      assert verify_button != nil
      assert verify_button.face.label == "Verify"
    end

    test "builds correct item structure for non-creator" do
      user =
        Factories.insert!(:member, %{
          creator: false,
          verified_at: nil,
          confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      # Non-creator should have make_creator button
      creator_button = Enum.find(item.action_buttons, &(&1.action.event == "make_creator"))
      assert creator_button != nil
      assert creator_button.face.label == "Make creator"
    end

    test "builds correct item structure for unconfirmed user" do
      user =
        Factories.insert!(:member, %{
          creator: true,
          verified_at: nil,
          confirmed_at: nil
        })

      user = Account.Public.get_user!(user.id, [:profile])
      item = AccountViewBuilder.build_user_item(user)

      # Unconfirmed user should have activate button
      activate_button = Enum.find(item.action_buttons, &(&1.action.event == "activate_user"))
      assert activate_button != nil
      assert activate_button.face.label == "Activate"
    end
  end
end
