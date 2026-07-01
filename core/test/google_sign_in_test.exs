defmodule GoogleSignIn.Test do
  use Core.DataCase, async: true

  alias Core.Factories

  describe "user_attrs/1" do
    test "maps proprietary fields to the normalized Account.User attrs" do
      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "user@example.com",
        "given_name" => "Re",
        "family_name" => "Searcher"
      }

      attrs = GoogleSignIn.user_attrs(userinfo)

      assert attrs.email == "user@example.com"
      assert attrs.displayname == "Re"
      assert attrs.fullname == "Re Searcher"
      assert %NaiveDateTime{} = attrs.verified_at
      refute Map.has_key?(attrs, :creator)
    end
  end

  describe "get/1" do
    test "returns the satellite linked to the user" do
      user = Factories.insert!(:member)
      satellite = Repo.insert!(%GoogleSignIn.User{sub: "test", user: user})

      assert GoogleSignIn.get(user).id == satellite.id
    end

    test "returns nil when the user has no satellite" do
      user = Factories.insert!(:member)

      assert GoogleSignIn.get(user) == nil
    end
  end

  describe "attach/2" do
    test "inserts a satellite row linked to the user" do
      user = Factories.insert!(:member, %{email: "user@example.com"})

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "user@example.com",
        "email_verified" => true,
        "given_name" => "First",
        "family_name" => "Last"
      }

      {:ok, satellite} = GoogleSignIn.attach(user, userinfo)

      assert satellite.user_id == user.id
      assert satellite.sub == userinfo["sub"]
      assert satellite.email == "user@example.com"
      assert satellite.email_verified == true
    end
  end

  describe "refresh/2" do
    test "replaces userinfo on the existing satellite without touching sub or user" do
      user = Factories.insert!(:member)

      original = %{
        "sub" => "stable",
        "email" => "first@example.com",
        "given_name" => "First"
      }

      {:ok, before} = GoogleSignIn.attach(user, original)

      updated = %{
        "sub" => "stable",
        "email" => "second@example.com",
        "given_name" => "Second"
      }

      refreshed = GoogleSignIn.refresh(user, updated)

      assert refreshed.id == before.id
      assert refreshed.user_id == user.id
      assert refreshed.sub == "stable"
      assert refreshed.email == "second@example.com"
      assert refreshed.given_name == "Second"
    end
  end
end
