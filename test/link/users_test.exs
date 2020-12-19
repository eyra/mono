defmodule Link.UsersTest do
  use Link.DataCase

  alias Link.Factories

  describe "user" do
    alias Link.Users

    setup :user_fixture

    test "get_user_profile!/1 returns an empty user profile when it does not yet exist", %{
      user: user
    } do
      assert Users.get_profile(user.id) |> Map.get(:user_id) == user.id
    end

    test "get_user_profile!/1 returns the same user profile for the user with the given id", %{
      user: user
    } do
      profile = Users.get_profile(user.id)
      assert Users.get_profile(user.id) |> Map.get(:id) == profile.id
    end

    test "get_user_profile!/1 returns the user profile when given a user", %{
      user: user
    } do
      assert Users.get_profile(user) == Users.get_profile(user.id)
    end

    test "update_user_profile/2 updates the user profile", %{
      user: user
    } do
      {:ok, _} = user |> Users.get_profile() |> Users.update_profile(%{fullname: "Update Test", displayname: "Update"})
      assert user |> Users.get_profile() |> Map.get(:fullname) == "Update Test"
    end

    defp user_fixture(context) do
      context
      |> Map.put(:user, Factories.get_or_create_user())
    end
  end
end
