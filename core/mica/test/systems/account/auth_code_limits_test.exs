defmodule Systems.Account.AuthCodeLimitsTest do
  use Core.DataCase, async: true

  import Ecto.Query

  alias Core.Factories
  alias Core.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeLimits
  alias Systems.Account.AuthCodeModel
  alias Systems.Rate.CounterModel

  @remote_ip "203.0.113.10"
  @other_ip "198.51.100.20"

  defp unique_email(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}@example.com"
  end

  defp insert_code(email, user_id \\ nil) do
    {code, auth_code} = AuthCodeModel.build(email, user_id)
    Repo.insert!(auth_code)
    {code, if(code == "000000", do: "000001", else: "000000")}
  end

  # Drops the counters of every window of `seconds`, as if the current one
  # had ended.
  defp end_windows(seconds) do
    from(c in CounterModel,
      where: fragment("extract(epoch from ? - ?) = ?", c.expires_at, c.window_start, ^seconds)
    )
    |> Repo.delete_all()
  end

  defp delete_codes(email) do
    from(t in AuthCodeModel, where: t.email == ^email) |> Repo.delete_all()
  end

  describe "guards" do
    test "generate_otp/2 crashes without a network address" do
      assert_raise FunctionClauseError, fn ->
        Account.Public.generate_otp("a@example.com", nil)
      end
    end

    test "verify_otp/3 crashes without a network address" do
      assert_raise FunctionClauseError, fn ->
        Account.Public.verify_otp("a@example.com", "123456", nil)
      end
    end
  end

  describe "a normal sign-in" do
    test "a person who mistypes and asks for a new code still signs in" do
      user = Factories.insert!(:member)

      assert :ok = Account.Public.generate_otp(user.email, @remote_ip)
      assert {:error, :invalid} = Account.Public.verify_otp(user.email, "000000", @remote_ip)
      assert {:error, :invalid} = Account.Public.verify_otp(user.email, "000000", @remote_ip)

      assert :ok = Account.Public.generate_otp(user.email, @remote_ip)
      delete_codes(user.email)
      {code, _wrong_code} = insert_code(user.email, user.id)

      assert {:ok, %{id: user_id}} = Account.Public.verify_otp(user.email, code, @remote_ip)
      assert user_id == user.id
    end

    test "many people behind one network address each sign in" do
      for _ <- 1..60 do
        email = unique_email("shared-network")
        assert :ok = Account.Public.generate_otp(email, @remote_ip)

        delete_codes(email)
        {code, wrong_code} = insert_code(email)

        assert {:error, :invalid} = Account.Public.verify_otp(email, wrong_code, @remote_ip)
        assert {:ok, nil} = Account.Public.verify_otp(email, code, @remote_ip)
      end
    end
  end

  describe "requesting codes" do
    test "an email address gets 10 codes per hour" do
      email = unique_email("requests")

      for _ <- 1..10, do: assert(AuthCodeLimits.allow_request?(email, @remote_ip))
      refute AuthCodeLimits.allow_request?(email, @other_ip)

      end_windows(3600)
      assert AuthCodeLimits.allow_request?(email, @remote_ip)
    end

    test "a network address gets 200 codes per hour, for any email addresses" do
      for _ <- 1..200 do
        assert AuthCodeLimits.allow_request?(unique_email("network"), @remote_ip)
      end

      email = unique_email("network")
      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @remote_ip)
      assert Repo.one(AuthCodeModel.active_query(email)) == nil

      assert :ok = Account.Public.generate_otp(email, @other_ip)
    end

    test "IPv6 addresses count by their /64 network" do
      for i <- 1..200 do
        assert AuthCodeLimits.allow_request?(unique_email("v6"), "2001:db8:1:2::#{i}")
      end

      refute AuthCodeLimits.allow_request?(unique_email("v6"), "2001:db8:1:2:ffff::1")
      assert AuthCodeLimits.allow_request?(unique_email("v6"), "2001:db8:1:3::1")
    end

    test "an email address that can't check codes gets no new code" do
      email = unique_email("locked")

      for _ <- 1..10, do: assert(AuthCodeLimits.allow_check?(email, @remote_ip))

      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @other_ip)
    end
  end

  describe "checking codes" do
    test "an email address gets 10 checks per hour, across its codes" do
      email = unique_email("checks")

      {_code, wrong_code} = insert_code(email)

      for _ <- 1..5,
          do:
            assert({:error, :invalid} = Account.Public.verify_otp(email, wrong_code, @remote_ip))

      delete_codes(email)
      {_code, wrong_code} = insert_code(email)

      for _ <- 1..5,
          do: assert({:error, :invalid} = Account.Public.verify_otp(email, wrong_code, @other_ip))

      delete_codes(email)
      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} = Account.Public.verify_otp(email, code, "192.0.2.30")
      assert Repo.one(AuthCodeModel.active_query(email)).attempts == 0

      end_windows(3600)
      assert {:ok, nil} = Account.Public.verify_otp(email, code, @remote_ip)
    end

    test "an email address gets 30 checks per day" do
      email = unique_email("daily")

      for _ <- 1..3 do
        for _ <- 1..10, do: assert(AuthCodeLimits.allow_check?(email, @remote_ip))
        end_windows(3600)
      end

      refute AuthCodeLimits.allow_check?(email, @remote_ip)

      end_windows(86_400)
      assert AuthCodeLimits.allow_check?(email, @remote_ip)
    end

    test "a network address gets 200 checks per hour, for any email addresses" do
      for _ <- 1..200 do
        assert AuthCodeLimits.allow_check?(unique_email("network"), @remote_ip)
      end

      email = unique_email("network")
      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} = Account.Public.verify_otp(email, code, @remote_ip)
      assert {:ok, nil} = Account.Public.verify_otp(email, code, @other_ip)
    end

    test "checks without an active code don't count" do
      email = unique_email("no-code")

      for _ <- 1..20 do
        assert {:error, :not_found} = Account.Public.verify_otp(email, "123456", @remote_ip)
      end

      {code, _wrong_code} = insert_code(email)
      assert {:ok, nil} = Account.Public.verify_otp(email, code, @remote_ip)
    end

    test "case variants of an email address share its limits" do
      email = unique_email("variants")

      for _ <- 1..10,
          do: assert(AuthCodeLimits.allow_check?(email, @remote_ip))

      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} =
               Account.Public.verify_otp(String.upcase(email), code, @remote_ip)
    end
  end

  describe "network/1" do
    test "keeps an IPv4 address" do
      assert AuthCodeLimits.network("203.0.113.10") == "203.0.113.10"
    end

    test "counts an IPv6 address by its /64 prefix" do
      assert AuthCodeLimits.network("2001:db8:1:2:3:4:5:6") == "2001:db8:1:2::/64"
    end

    test "counts an IPv4-mapped IPv6 address as IPv4" do
      assert AuthCodeLimits.network("::ffff:203.0.113.10") == "203.0.113.10"
    end
  end
end
