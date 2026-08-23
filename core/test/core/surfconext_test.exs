defmodule Core.SurfConext.Test do
  use Core.DataCase, async: true

  alias Core.Factories
  alias Core.SurfConext

  describe "user_attrs/1" do
    test "maps proprietary fields to the normalized Account.User attrs" do
      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "researcher@uva.nl",
        "given_name" => "Re",
        "family_name" => "Searcher"
      }

      attrs = SurfConext.user_attrs(userinfo)

      assert attrs.email == "researcher@uva.nl"
      assert attrs.displayname == "Re"
      assert attrs.creator == true
      assert attrs.fullname == "Re Searcher"
      assert %NaiveDateTime{} = attrs.confirmed_at
    end

    test "displayname falls back to fullname when given_name is missing" do
      userinfo = %{"sub" => "x", "email" => "x@uva.nl", "family_name" => "Only"}

      attrs = SurfConext.user_attrs(userinfo)

      assert attrs.displayname == "Only"
    end

    test "raises when email is missing" do
      userinfo = %{"sub" => "x", "given_name" => "Re"}

      assert_raise SurfConext.SurfConextError, fn -> SurfConext.user_attrs(userinfo) end
    end
  end

  describe "get/1" do
    test "returns the satellite linked to the user" do
      user = Factories.insert!(:member)
      satellite = Repo.insert!(%SurfConext.User{sub: "x", user: user})

      assert SurfConext.get(user).id == satellite.id
    end

    test "returns nil when the user has no satellite" do
      user = Factories.insert!(:member)

      assert SurfConext.get(user) == nil
    end
  end

  describe "attach/2" do
    test "inserts a satellite row linked to the user" do
      user = Factories.insert!(:member, %{email: "researcher@uva.nl"})

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "researcher@uva.nl",
        "given_name" => "Re"
      }

      {:ok, satellite} = SurfConext.attach(user, userinfo)

      assert satellite.user_id == user.id
      assert satellite.sub == userinfo["sub"]
      assert satellite.email == "researcher@uva.nl"
      assert satellite.userinfo == userinfo
    end
  end

  describe "refresh/2" do
    test "replaces userinfo on the existing satellite without touching sub or user" do
      user = Factories.insert!(:member)

      original = %{"sub" => "stable", "email" => "first@uva.nl", "given_name" => "First"}
      {:ok, before} = SurfConext.attach(user, original)

      updated = %{"sub" => "stable", "email" => "second@uva.nl", "given_name" => "Second"}
      refreshed = SurfConext.refresh(user, updated)

      assert refreshed.id == before.id
      assert refreshed.user_id == user.id
      assert refreshed.sub == "stable"
      assert refreshed.userinfo == updated
    end
  end
end
