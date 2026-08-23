defmodule Core.IdentityTest do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper

  alias Core.Factories
  alias Core.Identity
  alias Core.SurfConext
  alias Systems.Account

  describe "authenticate/2 — SURFconext" do
    test "registers a new Account.User and attaches a satellite when neither exists" do
      isolate_signals()

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "new@uva.nl",
        "given_name" => "New",
        "family_name" => "Researcher"
      }

      {:ok, %{user: user, first_time?: first_time?}} =
        Identity.authenticate(SurfConext, userinfo)

      assert first_time? == true
      assert user.email == "new@uva.nl"
      assert user.creator == true
      assert SurfConext.get(user) != nil
      assert_signal_dispatched({:user, :created})
    end

    test "attaches a satellite to an existing Account.User (the link case)" do
      existing = Factories.insert!(:member, %{email: "existing@uva.nl"})

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "existing@uva.nl",
        "given_name" => "Existing"
      }

      {:ok, %{user: user, first_time?: first_time?}} =
        Identity.authenticate(SurfConext, userinfo)

      assert first_time? == false
      assert user.id == existing.id
      assert SurfConext.get(user) != nil
    end

    test "refreshes the satellite on subsequent sign-ins" do
      user = Factories.insert!(:member, %{email: "repeat@uva.nl"})

      first = %{
        "sub" => "stable",
        "email" => "repeat@uva.nl",
        "given_name" => "First"
      }

      {:ok, _} = Identity.authenticate(SurfConext, first)

      second = %{
        "sub" => "stable",
        "email" => "repeat@uva.nl",
        "given_name" => "Second"
      }

      {:ok, %{user: same_user, first_time?: first_time?}} =
        Identity.authenticate(SurfConext, second)

      assert first_time? == false
      assert same_user.id == user.id

      satellite = SurfConext.get(same_user)
      assert satellite.userinfo == second
    end

    test "does not touch the existing user's email or displayname when linking" do
      _existing =
        Factories.insert!(:member, %{
          email: "stable@uva.nl",
          displayname: "Local Display"
        })

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "stable@uva.nl",
        "given_name" => "From SURFconext"
      }

      {:ok, %{user: user}} = Identity.authenticate(SurfConext, userinfo)

      reloaded = Account.Public.get_user!(user.id)
      assert reloaded.email == "stable@uva.nl"
      assert reloaded.displayname == "Local Display"
    end
  end

  describe "authenticate/3 — register_overrides" do
    test "merges overrides into the registered user (Google passes creator?)" do
      isolate_signals()

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "fresh@example.com",
        "email_verified" => true,
        "given_name" => "Fresh",
        "family_name" => "User"
      }

      {:ok, %{user: user, first_time?: true}} =
        Identity.authenticate(GoogleSignIn, userinfo, %{creator: false})

      assert user.creator == false
    end

    test "overrides have no effect when the user already exists" do
      existing = Factories.insert!(:member, %{email: "preset@example.com", creator: true})

      userinfo = %{
        "sub" => Faker.UUID.v4(),
        "email" => "preset@example.com",
        "email_verified" => true,
        "given_name" => "Whatever"
      }

      {:ok, %{user: user, first_time?: false}} =
        Identity.authenticate(GoogleSignIn, userinfo, %{creator: false})

      assert user.id == existing.id
      assert user.creator == true
    end
  end
end
