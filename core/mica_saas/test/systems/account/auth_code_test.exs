defmodule MicaSaas.Systems.Account.AuthCodeTest do
  use Mica.DataCase, async: true

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeModel

  # Sign-ins count per network address in rate_counters. Async test modules
  # write them in parallel transactions, so a shared address makes their
  # sign-ins wait on each other.
  setup do
    <<a, b, c>> = <<System.unique_integer([:positive])::24>>
    %{remote_ip: "10.#{a}.#{b}.#{c}"}
  end

  defp unique_email(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}@example.com"
  end

  describe "Account.Public.generate_otp/2" do
    test "inserts an auth code for the email", %{remote_ip: remote_ip} do
      email = "new@example.com"
      Account.Public.generate_otp(email, remote_ip)

      assert Repo.one(AuthCodeModel.active_query(email)) != nil
    end

    test "replaces existing auth code", %{remote_ip: remote_ip} do
      email = "user@example.com"
      Account.Public.generate_otp(email, remote_ip)
      Account.Public.generate_otp(email, remote_ip)

      count = Repo.aggregate(from(t in AuthCodeModel, where: t.email == ^email), :count)
      assert count == 1
    end

    test "links user_id when account exists", %{remote_ip: remote_ip} do
      user = Factories.insert!(:member)
      Account.Public.generate_otp(user.email, remote_ip)

      auth_code = Repo.one(AuthCodeModel.active_query(user.email))
      assert auth_code.user_id == user.id
    end

    test "leaves user_id nil when no account exists", %{remote_ip: remote_ip} do
      Account.Public.generate_otp("brand-new@example.com", remote_ip)

      auth_code = Repo.one(AuthCodeModel.active_query("brand-new@example.com"))
      assert auth_code.user_id == nil
    end
  end

  describe "Account.Public.generate_otp/2 rate limiting" do
    test "permits requests under the per-email limit", %{remote_ip: remote_ip} do
      email = unique_email("under-limit")

      assert :ok = Account.Public.generate_otp(email, remote_ip)
      assert :ok = Account.Public.generate_otp(email, remote_ip)
      assert :ok = Account.Public.generate_otp(email, remote_ip)
    end

    test "returns {:error, :rate_limited} after exceeding the per-email limit", %{
      remote_ip: remote_ip
    } do
      email = unique_email("over-limit")

      Account.Public.generate_otp(email, remote_ip)
      Account.Public.generate_otp(email, remote_ip)
      Account.Public.generate_otp(email, remote_ip)

      assert {:error, :rate_limited} = Account.Public.generate_otp(email, remote_ip)
    end

    test "tracks limits per email independently", %{remote_ip: remote_ip} do
      email_exhausted = unique_email("exhausted")
      email_fresh = unique_email("fresh")

      Account.Public.generate_otp(email_exhausted, remote_ip)
      Account.Public.generate_otp(email_exhausted, remote_ip)
      Account.Public.generate_otp(email_exhausted, remote_ip)
      assert {:error, :rate_limited} = Account.Public.generate_otp(email_exhausted, remote_ip)

      assert :ok = Account.Public.generate_otp(email_fresh, remote_ip)
    end
  end

  describe "email variants" do
    test "case and whitespace variants of one email share a single code", %{remote_ip: remote_ip} do
      user = Factories.insert!(:member)

      email = String.downcase(user.email)

      :ok = Account.Public.generate_otp(user.email, remote_ip)
      :ok = Account.Public.generate_otp(String.upcase(user.email), remote_ip)
      :ok = Account.Public.generate_otp("  " <> user.email <> " ", remote_ip)

      codes =
        Repo.all(from(t in AuthCodeModel, where: fragment("lower(trim(?))", t.email) == ^email))

      assert [%{email: ^email, user_id: user_id}] = codes
      assert user_id == user.id
    end

    test "case variants of one email share one request limit", %{remote_ip: remote_ip} do
      email = unique_email("shared-limit")

      assert :ok = Account.Public.generate_otp(email, remote_ip)
      assert :ok = Account.Public.generate_otp(String.upcase(email), remote_ip)
      assert :ok = Account.Public.generate_otp(String.capitalize(email), remote_ip)

      assert {:error, :rate_limited} =
               Account.Public.generate_otp(" " <> String.upcase(email), remote_ip)
    end
  end
end
