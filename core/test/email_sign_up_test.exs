defmodule EmailSignUpTest do
  use Core.DataCase, async: false

  alias Systems.Account.User

  describe "register/2" do
    test "creates user and satellite for valid email" do
      assert {:ok, %User{} = user} = EmailSignUp.register("valid@example.com")
      assert user.email == "valid@example.com"
      assert user.hashed_password == "no-password-set"
      assert user.creator == false
      assert user.verified_at != nil

      satellite = EmailSignUp.get_by_user(user)
      assert satellite != nil
      assert satellite.user_id == user.id
      assert satellite.validated_at != nil
      assert satellite.validation_data != nil
    end

    test "stores full validation data from UserCheck" do
      assert {:ok, user} = EmailSignUp.register("valid@example.com")
      satellite = EmailSignUp.get_by_user(user)

      assert %{"disposable" => false, "mx" => true} = satellite.validation_data
    end

    test "rejects disposable email" do
      assert {:error, :disposable} = EmailSignUp.register("disposable@tempmail.com")
    end

    test "rejects email with invalid MX" do
      assert {:error, :invalid_mx} = EmailSignUp.register("nomx@nonexistent.com")
    end

    test "rejects blocklisted email" do
      assert {:error, :blocklisted} = EmailSignUp.register("blocklisted@badactor.com")
    end

    test "rejects role account" do
      assert {:error, :role_account} = EmailSignUp.register("role@company.com")
    end

    test "rejects invalid email format" do
      assert {:error, :invalid_format} = EmailSignUp.register("not-an-email")
    end

    test "rejects already registered email" do
      assert {:ok, _user} = EmailSignUp.register("unique@example.com")
      assert {:error, :already_registered} = EmailSignUp.register("unique@example.com")
    end

    test "fails open when UserCheck times out" do
      assert {:ok, %User{} = user} = EmailSignUp.register("error@example.com")

      satellite = EmailSignUp.get_by_user(user)
      assert satellite.validated_at == nil
      assert satellite.validation_data == nil
    end

    test "accepts custom rejection policy" do
      defmodule AcceptAllPolicy do
        @behaviour EmailSignUp.RejectionPolicy
        def reject?(_result), do: :ok
      end

      assert {:ok, _user} =
               EmailSignUp.register("disposable@tempmail.com", policy: AcceptAllPolicy)
    end
  end

  describe "link/2" do
    test "links email to existing user and creates satellite" do
      user = Factories.insert!(:member)
      new_email = "linked-#{System.unique_integer([:positive])}@example.com"

      assert {:ok, %User{} = updated_user} = EmailSignUp.link(user, new_email)
      assert updated_user.email == new_email
      assert updated_user.id == user.id

      satellite = EmailSignUp.get_by_user(updated_user)
      assert satellite != nil
      assert satellite.user_id == user.id
    end

    test "rejects invalid email format" do
      user = Factories.insert!(:member)
      assert {:error, :invalid_format} = EmailSignUp.link(user, "not-an-email")
    end

    test "rejects already registered email" do
      existing = Factories.insert!(:member, %{email: "taken@example.com"})
      user = Factories.insert!(:member)
      assert {:error, :already_registered} = EmailSignUp.link(user, existing.email)
    end

    test "rejects disposable email" do
      user = Factories.insert!(:member)
      assert {:error, :disposable} = EmailSignUp.link(user, "disposable@tempmail.com")
    end
  end

  describe "provisional?/1" do
    test "returns true for fresh email signup user" do
      assert {:ok, user} = EmailSignUp.register("provisional@example.com")
      assert EmailSignUp.provisional?(user)
    end

    test "returns false after password is set" do
      assert {:ok, user} = EmailSignUp.register("activated@example.com")

      user
      |> User.password_changeset(%{password: "SecurePassword123!"})
      |> Repo.update!()
      |> then(&assert(not EmailSignUp.provisional?(&1)))
    end

    test "returns false after confirmation" do
      assert {:ok, user} = EmailSignUp.register("confirmed@example.com")

      user
      |> User.confirm_changeset()
      |> Repo.update!()
      |> then(&assert(not EmailSignUp.provisional?(&1)))
    end
  end

  describe "get_by_user/1" do
    test "returns satellite for email signup user" do
      assert {:ok, user} = EmailSignUp.register("lookup@example.com")
      assert %EmailSignUp.UserModel{} = EmailSignUp.get_by_user(user)
    end

    test "returns nil for non-email-signup user" do
      user =
        Core.Factories.insert!(:member, %{
          email: "regular@example.com",
          password: Core.Factories.valid_user_password()
        })

      assert EmailSignUp.get_by_user(user) == nil
    end
  end

  describe "opt_out/1" do
    test "deletes user and cascade deletes satellite" do
      assert {:ok, user} = EmailSignUp.register("optout@example.com")
      user_id = user.id

      assert {:ok, _} = EmailSignUp.opt_out(user)

      assert Repo.get(User, user_id) == nil
      assert Repo.get_by(EmailSignUp.UserModel, user_id: user_id) == nil
    end
  end
end
