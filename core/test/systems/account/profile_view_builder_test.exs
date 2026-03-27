defmodule Systems.Account.ProfileViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      profile = Account.Public.get_profile(user)
      entity = Account.UserProfileEditModel.create(user, profile)

      %{user: user, entity: entity}
    end

    test "builds view model with title", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.title == dgettext("eyra-account", "profile.tab.profile.title")
    end

    test "builds view model with changeset", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert %Ecto.Changeset{} = vm.changeset
    end

    test "builds view model with entity", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.entity == entity
    end

    test "builds view model with user", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.user == user
    end

    test "builds view model with signout button", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.signout_button.action.type == :http_delete
      assert vm.signout_button.action.to == "/user/session"
      assert vm.signout_button.face.type == :secondary
    end

    test "builds view model with labels", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.fullname_label == dgettext("eyra-account", "fullname.label")
      assert vm.displayname_label == dgettext("eyra-account", "displayname.label")
      assert vm.title_label == dgettext("eyra-account", "professionaltitle.label")
      assert vm.email_label == dgettext("eyra-account", "email.label")
    end

    test "builds view model with photo labels", %{entity: entity, user: user} do
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.choose_photo_text == dgettext("eyra-account", "choose.profile.photo.file")

      assert vm.choose_other_photo_text ==
               dgettext("eyra-account", "choose.other.profile.photo.file")
    end

    test "includes photo_url from entity", %{user: user} do
      profile = Account.Public.get_profile(user)

      {:ok, updated_profile} =
        profile
        |> Account.UserProfileModel.changeset(%{photo_url: "https://example.com/photo.jpg"})
        |> Repo.update()

      entity = Account.UserProfileEditModel.create(user, updated_profile)
      vm = Account.ProfileViewBuilder.view_model(entity, %{user: user})

      assert vm.photo_url == "https://example.com/photo.jpg"
    end
  end
end
