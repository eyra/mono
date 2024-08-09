defmodule GoogleSignIn.Test do
  use Core.DataCase, async: true

  alias Core.Factories

  describe "get_user_by_sub/1" do
    test "get a user by their subject id" do
      user = Factories.insert!(:member)
      Repo.insert!(%GoogleSignIn.User{sub: "test", user: user})

      loaded_user = GoogleSignIn.get_user_by_sub("test")

      assert loaded_user.id == user.id
    end
  end

  describe "register_google_sign_in_user/1" do
    test "creates a user with a profile" do
      given_name = Faker.Person.first_name()
      family_name = Faker.Person.last_name()

      sso_info = %{
        "sub" => Faker.UUID.v4(),
        "name" => "#{given_name} #{family_name}",
        "email" => Faker.Internet.email(),
        "email_verified" => true,
        "given_name" => given_name,
        "family_name" => family_name,
        "picture" => Faker.Internet.url(),
        "locale" => "en"
      }

      {:ok, google_user} = GoogleSignIn.register_user(sso_info, false)

      for key <- Map.keys(sso_info) do
        assert Map.get(google_user, String.to_atom(key)) == Map.get(sso_info, key)
      end

      assert google_user.user.creator == false
      assert google_user.user.email == Map.get(sso_info, "email")
      assert google_user.user.displayname == "#{given_name}"
      assert google_user.user.profile.fullname == "#{given_name} #{family_name}"
    end
  end
end
