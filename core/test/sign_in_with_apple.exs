defmodule SignInWithApple.Test do
  use Core.DataCase, async: true

  alias Core.Factories

  describe "get_user_by_sub/1" do
    test "get a user by their subject id" do
      user = Factories.insert!(:member)
      Repo.insert!(%SignInWithApple.User{sub: "test", user: user})

      loaded_user = SignInWithApple.get_user_by_sub("test")

      assert loaded_user.id == user.id
    end
  end

  describe "register_apple_user/1" do
    test "creates a user with a profile" do
      for middle_name? <- [false, true] do
        middle_name = if middle_name?, do: Faker.Person.first_name()

        sso_info = %{
          sub: Faker.UUID.v4(),
          email: Faker.Internet.email(),
          is_private_email: :random.uniform(2) == 1,
          first_name: Faker.Person.first_name(),
          middle_name: middle_name,
          last_name: Faker.Person.last_name()
        }

        {:ok, apple_user} = SignInWithApple.register_user(sso_info)

        assert apple_user.sub == sso_info.sub
        assert apple_user.email == sso_info.email
        assert apple_user.is_private_email == sso_info.is_private_email
        assert apple_user.first_name == sso_info.first_name
        assert apple_user.middle_name == sso_info.middle_name
        assert apple_user.last_name == sso_info.last_name
        assert apple_user.user.email == sso_info.email
        assert String.contains?(apple_user.user.displayname, sso_info.first_name)
        assert String.contains?(apple_user.user.profile.fullname, sso_info.first_name)
        assert String.contains?(apple_user.user.profile.fullname, sso_info.last_name)

        if middle_name? do
          assert String.contains?(apple_user.user.profile.fullname, sso_info.middle_name)
        end
      end
    end
  end
end
