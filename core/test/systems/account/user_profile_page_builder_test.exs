defmodule Systems.Account.UserProfilePageBuilderTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.Account
  alias Systems.Pool

  describe "tab_keys/1" do
    test "includes features key when user is PANL participant" do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile, :features]
    end

    test "excludes features key when user is not PANL participant" do
      user = Factories.insert!(:member)
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile]
    end

    test "excludes features key when PANL pool does not exist" do
      user = Factories.insert!(:member)

      if panl_pool = Pool.Public.get_panl() do
        Repo.delete(panl_pool)
      end

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile]
    end
  end
end
