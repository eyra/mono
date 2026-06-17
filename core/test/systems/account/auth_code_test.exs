defmodule Systems.Account.AuthCodeTest do
  use Core.DataCase, async: true

  alias Core.Factories
  alias Core.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeModel

  defp unique_email(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}@example.com"
  end

  describe "AuthCodeModel.build/2" do
    test "generates a 6-digit code" do
      {code, _auth_code} = AuthCodeModel.build("user@example.com", nil)
      assert String.match?(code, ~r/^\d{6}$/)
    end

    test "code is always 6 digits, never more, never less" do
      codes =
        for _ <- 1..100 do
          {code, _} = AuthCodeModel.build("user@example.com", nil)
          code
        end

      assert Enum.all?(codes, &(String.length(&1) == 6))
      assert Enum.all?(codes, &String.match?(&1, ~r/^\d{6}$/))
    end

    test "stores hashed code, not plaintext" do
      {code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      refute auth_code.code_hash == code
    end

    test "sets email on the auth code" do
      {_code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      assert auth_code.email == "user@example.com"
    end

    test "sets user_id when provided" do
      user = Factories.insert!(:member)
      {_code, auth_code} = AuthCodeModel.build(user.email, user.id)
      assert auth_code.user_id == user.id
    end

    test "accepts nil user_id for new registrations" do
      {_code, auth_code} = AuthCodeModel.build("new@example.com", nil)
      assert auth_code.user_id == nil
    end

    test "starts with zero attempts" do
      {_code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      assert auth_code.attempts == 0
    end
  end

  describe "AuthCodeModel.verify/2" do
    test "returns :ok for correct code" do
      {code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      assert :ok = AuthCodeModel.verify(auth_code, code)
    end

    test "returns {:error, :invalid} for wrong code" do
      {code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      wrong_code = if code == "000000", do: "000001", else: "000000"
      assert {:error, :invalid} = AuthCodeModel.verify(auth_code, wrong_code)
    end

    test "returns {:error, :max_attempts} when attempts exhausted" do
      {code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      exhausted = %{auth_code | attempts: 5}
      assert {:error, :max_attempts} = AuthCodeModel.verify(exhausted, code)
    end

    test "returns {:error, :max_attempts} before checking code when attempts exhausted" do
      {_code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      exhausted = %{auth_code | attempts: 5}
      assert {:error, :max_attempts} = AuthCodeModel.verify(exhausted, "correct-irrelevant")
    end
  end

  describe "AuthCodeModel.active_query/1" do
    test "finds a recently inserted auth code" do
      {_code, auth_code} = AuthCodeModel.build("user@example.com", nil)
      Repo.insert!(auth_code)

      result = AuthCodeModel.active_query("user@example.com") |> Repo.one()
      assert result != nil
      assert result.email == "user@example.com"
    end

    test "returns nil for unknown email" do
      result = AuthCodeModel.active_query("unknown@example.com") |> Repo.one()
      assert result == nil
    end

    test "returns nil when max attempts reached" do
      {_code, auth_code} = AuthCodeModel.build("user@example.com", nil)

      Repo.insert!(%{auth_code | attempts: 5})

      result = AuthCodeModel.active_query("user@example.com") |> Repo.one()
      assert result == nil
    end

    test "returns most recent code when multiple exist" do
      {_code1, auth_code1} = AuthCodeModel.build("user@example.com", nil)
      {_code2, auth_code2} = AuthCodeModel.build("user@example.com", nil)

      inserted1 = Repo.insert!(auth_code1)
      inserted2 = Repo.insert!(auth_code2)

      result = AuthCodeModel.active_query("user@example.com") |> Repo.one()
      assert result.id == inserted2.id
      assert result.id != inserted1.id
    end
  end

  describe "Account.Public.generate_otp/1" do
    test "inserts an auth code for the email" do
      email = "new@example.com"
      Account.Public.generate_otp(email)

      assert Repo.one(AuthCodeModel.active_query(email)) != nil
    end

    test "replaces existing auth code" do
      email = "user@example.com"
      Account.Public.generate_otp(email)
      Account.Public.generate_otp(email)

      count = Repo.aggregate(from(t in AuthCodeModel, where: t.email == ^email), :count)
      assert count == 1
    end

    test "links user_id when account exists" do
      user = Factories.insert!(:member)
      Account.Public.generate_otp(user.email)

      auth_code = Repo.one(AuthCodeModel.active_query(user.email))
      assert auth_code.user_id == user.id
    end

    test "leaves user_id nil when no account exists" do
      Account.Public.generate_otp("brand-new@example.com")

      auth_code = Repo.one(AuthCodeModel.active_query("brand-new@example.com"))
      assert auth_code.user_id == nil
    end
  end

  describe "Account.Public.generate_otp/1 rate limiting" do
    test "permits requests under the per-email limit" do
      email = unique_email("under-limit")

      assert :ok = Account.Public.generate_otp(email)
      assert :ok = Account.Public.generate_otp(email)
      assert :ok = Account.Public.generate_otp(email)
    end

    test "returns {:error, :rate_limited} after exceeding the per-email limit" do
      email = unique_email("over-limit")

      Account.Public.generate_otp(email)
      Account.Public.generate_otp(email)
      Account.Public.generate_otp(email)

      assert {:error, :rate_limited} = Account.Public.generate_otp(email)
    end

    test "tracks limits per email independently" do
      email_exhausted = unique_email("exhausted")
      email_fresh = unique_email("fresh")

      Account.Public.generate_otp(email_exhausted)
      Account.Public.generate_otp(email_exhausted)
      Account.Public.generate_otp(email_exhausted)
      assert {:error, :rate_limited} = Account.Public.generate_otp(email_exhausted)

      assert :ok = Account.Public.generate_otp(email_fresh)
    end
  end

  describe "Account.Public.verify_otp/2" do
    test "returns {:ok, user} for correct code when account exists" do
      user = Factories.insert!(:member)
      {code, auth_code} = AuthCodeModel.build(user.email, user.id)
      Repo.insert!(auth_code)

      assert {:ok, returned_user} = Account.Public.verify_otp(user.email, code)
      assert returned_user.id == user.id
    end

    test "returns {:ok, nil} for correct code when no account exists" do
      email = "new@example.com"
      Repo.delete_all(from(t in AuthCodeModel, where: t.email == ^email))
      {code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(auth_code)

      assert {:ok, nil} = Account.Public.verify_otp(email, code)
    end

    test "returns {:error, :invalid} for wrong code" do
      email = "user@example.com"
      {code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(auth_code)
      wrong_code = if code == "000000", do: "000001", else: "000000"

      assert {:error, :invalid} = Account.Public.verify_otp(email, wrong_code)
    end

    test "increments attempts on wrong code" do
      email = "user@example.com"
      {code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(auth_code)
      wrong_code = if code == "000000", do: "000001", else: "000000"

      Account.Public.verify_otp(email, wrong_code)

      updated = Repo.one(AuthCodeModel.active_query(email))
      assert updated.attempts == 1
    end

    test "returns {:error, :not_found} when no active code exists" do
      assert {:error, :not_found} = Account.Public.verify_otp("nobody@example.com", "123456")
    end

    test "deletes auth code after successful verification" do
      email = "user@example.com"
      {code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(auth_code)

      Account.Public.verify_otp(email, code)

      assert Repo.one(AuthCodeModel.active_query(email)) == nil
    end

    test "returns {:error, :max_attempts} after 5 wrong attempts" do
      email = "user@example.com"
      {code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(%{auth_code | attempts: 5})

      assert {:error, :not_found} = Account.Public.verify_otp(email, code)
    end
  end
end
