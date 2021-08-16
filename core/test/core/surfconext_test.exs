defmodule Core.SurfConext.Test do
  use Core.DataCase, async: true
  import Core.Signals.Test

  alias Core.Factories

  describe "get_user_by_sub/1" do
    test "get a user by their subject id" do
      user = Factories.insert!(:member)
      Repo.insert!(%Core.SurfConext.User{sub: "test", user: user})

      loaded_user = Core.SurfConext.get_user_by_sub("test")

      assert loaded_user.id == user.id
    end
  end

  describe "register_surfconext_user/1" do
    test "creates a user with a profile" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "given_name" => Faker.Person.name(),
        "family_name" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl"
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.sub == Map.get(sso_info, "sub")
      assert surf_user.email == Map.get(sso_info, "email")
      assert surf_user.schac_home_organization == "eduid.nl"
      assert surf_user.user.email == Map.get(sso_info, "email")
      assert surf_user.user.displayname == "#{sso_info["given_name"]}"

      assert surf_user.user.profile.fullname ==
               "#{sso_info["given_name"]} #{sso_info["family_name"]}"
    end

    test "dispatches signal" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl"
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      message = assert_signal_dispatched(:user_created)
      assert message == %{user: surf_user}
    end

    test "assign the researcher role when the user is an employee" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl",
        "eduperson_affiliation" => ["member", "employee", "faculty"]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.user.researcher
    end

    test "assign the student role when the user is an student" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl",
        "eduperson_affiliation" => ["student"]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.user.student
    end
  end
end
