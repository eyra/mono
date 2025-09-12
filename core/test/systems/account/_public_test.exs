defmodule Systems.Account.PublicTest do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper

  alias Core.Factories

  alias Systems.Account
  alias Systems.Account.User
  alias Systems.Account.UserTokenModel

  import Core.AuthTestHelpers

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Account.Public.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = Factories.insert!(:member)
      assert %User{id: ^id} = Account.Public.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Account.Public.get_user_by_email_and_password(
               "unknown@example.com",
               Factories.valid_user_password()
             )
    end

    test "does not return the user if the email has not been confirmed" do
      password = Factories.valid_user_password()
      user = Factories.insert!(:member, %{confirmed_at: nil, password: password})
      refute Account.Public.get_user_by_email_and_password(user.email, password)
    end

    test "does not return the user if the password is not valid" do
      user = Factories.insert!(:member)

      refute Account.Public.get_user_by_email_and_password(
               user.email,
               Factories.valid_user_password()
             )
    end

    test "returns the user if the email and password are valid" do
      password = Factories.valid_user_password()
      %{id: id} = user = Factories.insert!(:member, %{password: password})

      assert %User{id: ^id} = Account.Public.get_user_by_email_and_password(user.email, password)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Account.Public.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = Factories.insert!(:member)
      assert %User{id: ^id} = Account.Public.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Account.Public.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Account.Public.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Account.Public.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = Factories.insert!(:member)
      {:error, changeset} = Account.Public.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Account.Public.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = Faker.Internet.email()

      {:ok, user} =
        Account.Public.register_user(%{email: email, password: Factories.valid_user_password()})

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Account.Public.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = Faker.Internet.email()
      password = Factories.valid_user_password()

      changeset =
        Account.Public.change_user_registration(%User{}, %{
          "email" => email,
          "password" => password
        })

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Account.Public.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      password = Factories.valid_user_password()
      %{user: Factories.insert!(:member, %{password: password}), password: password}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} =
        Account.Public.apply_user_email(user, Factories.valid_user_password(), %{})

      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Account.Public.apply_user_email(user, Factories.valid_user_password(), %{
          email: "not valid"
        })

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Account.Public.apply_user_email(user, Factories.valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = Factories.insert!(:member)

      {:error, changeset} =
        Account.Public.apply_user_email(user, Factories.valid_user_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Account.Public.apply_user_email(user, "invalid", %{email: Faker.Internet.email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user, password: password} do
      email = Faker.Internet.email()
      {:ok, user} = Account.Public.apply_user_email(user, password, %{email: email})
      assert user.email == email
      assert Account.Public.get_user!(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{user: Factories.insert!(:member)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Account.Public.deliver_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserTokenModel, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user =
        Factories.insert!(
          :member,
          %{
            confirmed_at:
              Faker.DateTime.backward(4) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
          }
        )

      email = Faker.Internet.email()

      token =
        extract_user_token(fn url ->
          Account.Public.deliver_update_email_instructions(
            %{user | email: email},
            user.email,
            url
          )
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Systems.Account.Public.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Systems.Account.Public.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Systems.Account.Public.update_user_email(
               %{user | email: "current@example.com"},
               token
             ) == :error

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserTokenModel, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Systems.Account.Public.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserTokenModel, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Account.Public.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      password = Factories.valid_user_password()

      changeset =
        Account.Public.change_user_password(%User{}, %{
          "password" => password
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      password = Factories.valid_user_password()
      %{user: Factories.insert!(:member, %{password: password}), password: password}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Systems.Account.Public.update_user_password(user, Factories.valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = Factories.valid_user_password() <> String.duplicate("_too_long_", 50)

      {:error, changeset} =
        Systems.Account.Public.update_user_password(user, Factories.valid_user_password(), %{
          password: too_long
        })

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Systems.Account.Public.update_user_password(user, "invalid", %{
          password: Factories.valid_user_password()
        })

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user, password: password} do
      new_password = Factories.valid_user_password()

      {:ok, user} =
        Systems.Account.Public.update_user_password(user, password, %{
          password: new_password
        })

      assert is_nil(user.password)
      assert Account.Public.get_user_by_email_and_password(user.email, new_password)
    end

    test "deletes all tokens for the given user", %{user: user, password: password} do
      _ = Account.Public.generate_user_session_token(user)

      {:ok, _} =
        Systems.Account.Public.update_user_password(user, password, %{
          password: Factories.valid_user_password()
        })

      refute Repo.get_by(UserTokenModel, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: Factories.insert!(:member)}
    end

    test "generates a token", %{user: user} do
      token = Account.Public.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserTokenModel, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserTokenModel{
          token: user_token.token,
          user_id: Factories.insert!(:member).id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = Factories.insert!(:member)
      token = Account.Public.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Account.Public.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Account.Public.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserTokenModel, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Account.Public.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = Factories.insert!(:member)
      token = Account.Public.generate_user_session_token(user)
      assert Account.Public.delete_session_token(token) == :ok
      refute Account.Public.get_user_by_session_token(token)
    end
  end

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

  describe "reset_user_password/2" do
    setup do
      %{user: Factories.insert!(:member)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Account.Public.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "at least one digit or punctuation character",
                 "at least one upper case character",
                 "should be at least 12 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Account.Public.reset_user_password(user, %{password: too_long})
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      new_valid_password = Factories.valid_user_password()

      {:ok, updated_user} =
        Account.Public.reset_user_password(user, %{password: new_valid_password})

      assert is_nil(updated_user.password)
      assert Account.Public.get_user_by_email_and_password(user.email, new_valid_password)
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Account.Public.generate_user_session_token(user)

      {:ok, _} =
        Account.Public.reset_user_password(user, %{password: Factories.valid_user_password()})

      refute Repo.get_by(UserTokenModel, user_id: user.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "profile" do
    alias Systems.Account

    setup do
      isolate_signals()
      %{user: Factories.insert!(:member)}
    end

    test "get_user_profile!/1 returns an empty user profile when it does not yet exist", %{
      user: user
    } do
      assert Account.Public.get_profile(user.id) |> Map.get(:user_id) == user.id
    end

    test "get_user_profile!/1 returns the same user profile for the user with the given id", %{
      user: user
    } do
      profile = Account.Public.get_profile(user.id)
      assert Account.Public.get_profile(user.id) |> Map.get(:id) == profile.id
    end

    test "get_user_profile!/1 returns the user profile when given a user", %{
      user: user
    } do
      assert Account.Public.get_profile(user) == Systems.Account.Public.get_profile(user.id)
    end

    test "update_user_profile/2 updates the user profile", %{
      user: user
    } do
      user_changeset = Account.User.user_profile_changeset(user, %{})

      profile_changeset =
        Account.UserProfileModel.changeset(user.profile, %{
          fullname: "Update Test",
          displayname: "Update"
        })

      {:ok, _} = Systems.Account.Public.update_user_profile(user_changeset, profile_changeset)

      assert user |> Account.Public.get_profile() |> Map.get(:fullname) == "Update Test"
      assert_signal_dispatched({:user_profile, :updated})
    end
  end

  describe "visited_pages" do
    alias Systems.Account

    setup do
      isolate_signals()

      url_resolver = fn target, _ ->
        case target do
          Systems.Account.UserSettings -> "/settings"
          Account.UserProfilePage -> "/profile"
        end
      end

      %{user: Factories.insert!(:member), url_resolver: url_resolver}
    end

    test "mark_as_visited/2 updates the user", %{
      user: user
    } do
      user_changeset = Account.User.user_profile_changeset(user, %{creator: true})

      {:ok, %{user: user}} = Systems.Account.Public.update_user(user_changeset)
      {:ok, %{user: user}} = Account.Public.mark_as_visited(user, :settings)

      assert user |> Map.get(:visited_pages) == ["settings"]
      assert_signal_dispatched(:visited_pages_updated)
    end

    test "visited?/2 updates the user", %{
      user: user
    } do
      Account.Public.mark_as_visited(user, :settings)
      assert user.id |> Account.Public.get_user!() |> Account.Public.visited?(:settings)
    end
  end
end
