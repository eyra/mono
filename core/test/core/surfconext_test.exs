defmodule Core.SurfConext.Test do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper
  import Systems.NextAction.TestHelper

  alias Core.Factories

  describe "get_user_by_sub/1" do
    test "get a user by their subject id" do
      user = Factories.insert!(:member)
      Repo.insert!(%Core.SurfConext.User{sub: "test", user: user})

      loaded_user = Core.SurfConext.get_user_by_sub("test")

      assert loaded_user.id == user.id
    end
  end

  describe "get_surfconext_user_by_user/1" do
    test "get a surf conext user by a core user reference" do
      core_user = Factories.insert!(:member)
      surfconext_user = Repo.insert!(%Core.SurfConext.User{sub: "test", user: core_user})

      loaded_surfconext_user = Core.SurfConext.get_surfconext_user_by_user(core_user)

      assert loaded_surfconext_user.id == surfconext_user.id
    end
  end

  describe "register_surfconext_user/1" do
    test "fails to register: missing email" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "given_name" => Faker.Person.name(),
        "family_name" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      assert_raise Core.SurfConext.SurfConextError, fn ->
        Core.SurfConext.register_user(sso_info)
      end
    end

    test "creates a user with a profile" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "given_name" => Faker.Person.name(),
        "family_name" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.sub == Map.get(sso_info, "sub")
      assert surf_user.email == Map.get(sso_info, "email")
      assert surf_user.schac_home_organization == "eduid.nl"

      assert surf_user.schac_personal_unique_code == [
               "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
             ]

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
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, %{user: user}} = Core.SurfConext.register_user(sso_info)

      message = assert_signal_dispatched({:user, :created})
      assert %{user: ^user} = message
    end

    test "assign the researcher role when the user is an employee" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["member", "employee", "faculty"],
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.user.researcher
    end

    test "assign the student role when the user is an student" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["student"],
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.user.student
    end

    test "assign both student and employee role when the user is an employee but has a student email" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => "some-person@student.vu.nl",
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["employee"],
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.user.researcher
      # Assigned via the email pattern
      assert surf_user.user.student
    end

    test "creates next action when the registered user is a student" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "eduperson_affiliation" => ["student"],
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, %{user: user}} = Core.SurfConext.register_user(sso_info)

      assert_next_action(user, "/user/profile?tab=settings")
    end
  end

  describe "update_surfconext_user/1" do
    test "updates an existing surfconext user (only specific fields will be changed)" do
      sso_info1 = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "given_name" => Faker.Person.name(),
        "family_name" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:2765287"
        ]
      }

      {:ok, surf_user1} = Core.SurfConext.register_user(sso_info1)

      sso_info2 = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "given_name" => Faker.Person.name(),
        "family_name" => Faker.Person.name(),
        "schac_home_organization" => "something.else.nl",
        "schac_personal_unique_code" => [
          "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:1212121"
        ]
      }

      surf_user2 = Core.SurfConext.update_user(surf_user1.user, sso_info2)
      core_user2 = Core.Accounts.get_user!(surf_user2.user_id)
      profile2 = Core.Accounts.get_profile(core_user2)

      assert surf_user2.schac_personal_unique_code == sso_info2["schac_personal_unique_code"]

      assert surf_user2.sub != sso_info2["sub"]
      assert surf_user2.email != sso_info2["sub"]
      assert surf_user2.schac_home_organization != sso_info2["schac_home_organization"]

      assert core_user2.email != sso_info2["email"]
      assert core_user2.displayname != sso_info2["displayname"]

      assert profile2.fullname !=
               "#{sso_info2["given_name"]} #{sso_info2["family_name"]}"
    end
  end
end
