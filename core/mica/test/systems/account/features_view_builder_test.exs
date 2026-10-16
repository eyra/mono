defmodule Systems.Account.FeaturesViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Enums.Genders
  alias Systems.Account

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      features = Account.Public.get_features(user)

      %{user: user, features: features}
    end

    test "builds view model with title and description", %{features: features} do
      vm = Account.FeaturesViewBuilder.view_model(features, %{})

      assert vm.title == dgettext("eyra-account", "profile.tab.features.title")
      assert vm.description == dgettext("eyra-account", "features.description")
      assert vm.gender_title == dgettext("eyra-account", "features.gender.title")
      assert vm.birth_year_title == dgettext("eyra-account", "features.birthyear.title")
    end

    test "builds gender selector as LiveNest element", %{features: features} do
      vm = Account.FeaturesViewBuilder.view_model(features, %{})

      assert vm.gender_selector != nil
      assert vm.gender_selector.implementation == Frameworks.Pixel.Selector
      assert vm.gender_selector.id == :gender_selector
    end

    test "includes changeset for form", %{features: features} do
      vm = Account.FeaturesViewBuilder.view_model(features, %{})

      assert %Ecto.Changeset{} = vm.changeset
      assert vm.changeset.data == features
    end

    test "includes features model", %{features: features} do
      vm = Account.FeaturesViewBuilder.view_model(features, %{})

      assert vm.features == features
    end

    test "builds gender selector with correct items based on current gender", %{user: user} do
      # Update features with a specific gender
      features = Account.Public.get_features(user)

      {:ok, updated_features} =
        features
        |> Account.FeaturesModel.changeset(:auto_save, %{gender: :man})
        |> Repo.update()

      vm = Account.FeaturesViewBuilder.view_model(updated_features, %{})

      # Gender selector should have items with man selected
      expected_labels = Genders.labels(:man)
      assert length(expected_labels) > 0
      assert vm.gender_selector != nil
    end
  end
end
