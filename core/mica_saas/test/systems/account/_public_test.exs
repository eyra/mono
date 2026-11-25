defmodule MicaSaas.Systems.Account.PublicTest do
  use Mica.DataCase

  alias Mica.Factories

  alias Systems.Account
  alias Systems.Account.User
  alias Systems.Account.UserTokenModel

  import Mica.AuthTestHelpers

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: Factories.insert!(:member, %{confirmed_at: nil})}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserTokenModel, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/2" do
    setup do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Account.Public.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Account.Public.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserTokenModel, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Account.Public.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: Factories.insert!(:member)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserTokenModel, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = Factories.insert!(:member)

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Account.Public.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserTokenModel, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Account.Public.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserTokenModel, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Account.Public.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end
  end
end
