defmodule Core.SurfConext.Test do
  use Link.DataCase, async: true

  alias Link.Factories
  alias Core.SurfContext

  describe "get_user_by_sub/1" do
    test "get a user by their subject id" do
      user = Factories.insert!(:member)
      Repo.insert!(%SurfConext.User{sub: "test", user: user})

      loaded_user = SurfConext.get_user_by_sub("test")

      assert loaded_user.id == user.id
    end
  end

  describe "register_surfconext_user/1" do
    test "creates a user with a profile" do
      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "email" => Faker.Internet.email(),
        "preferred_username" => Faker.Person.name(),
        "schac_home_organization" => "eduid.nl"
      }

      {:ok, surf_user} = Core.SurfConext.register_user(sso_info)

      assert surf_user.sub == Map.get(sso_info, "sub")
      assert surf_user.email == Map.get(sso_info, "email")
      assert surf_user.schac_home_organization == "eduid.nl"
      assert surf_user.user.email == Map.get(sso_info, "email")
      assert surf_user.user.displayname == Map.get(sso_info, "preferred_username")
      assert surf_user.user.profile.fullname == Map.get(sso_info, "preferred_username")
    end
  end
end
