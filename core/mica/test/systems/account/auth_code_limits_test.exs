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

  defp network_ip(i), do: "192.0.2.#{i}"

  # A request or check as `Account.Public` counts it, without the per-minute
  # quota per email address that the service keeps in memory.
  defp request?(email, remote_ip),
    do: AuthCodeLimits.allow_request?(email, remote_ip) and AuthCodeLimits.count_request?(email)

  defp check?(email, remote_ip),
    do: AuthCodeLimits.allow_check?(email, remote_ip) and AuthCodeLimits.count_check?(email)

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
    test "an email address gets 10 codes per hour from one network address" do
      email = unique_email("requests")

      for _ <- 1..10, do: assert(request?(email, @remote_ip))
      refute request?(email, @remote_ip)
      assert request?(email, @other_ip)

      end_windows(3600)
      assert request?(email, @remote_ip)
    end

    test "an email address gets 50 codes per day across network addresses" do
      email = unique_email("requests-daily")

      for i <- 1..5, _ <- 1..10, do: assert(request?(email, network_ip(i)))
      refute request?(email, network_ip(6))

      end_windows(86_400)
      assert request?(email, network_ip(6))
    end

    test "a network address gets 200 codes per hour, for any email addresses" do
      for _ <- 1..200 do
        assert request?(unique_email("network"), @remote_ip)
      end

      email = unique_email("network")
      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @remote_ip)
      assert Repo.one(AuthCodeModel.active_query(email)) == nil

      assert :ok = Account.Public.generate_otp(email, @other_ip)
    end

    test "IPv6 addresses count by their /64 network" do
      for i <- 1..200 do
        assert request?(unique_email("v6"), "2001:db8:1:2::#{i}")
      end

      refute request?(unique_email("v6"), "2001:db8:1:2:ffff::1")
      assert request?(unique_email("v6"), "2001:db8:1:3::1")
    end

    test "an email address that can't check codes from a network address gets no new code there" do
      email = unique_email("locked")

      for _ <- 1..10, do: assert(check?(email, @remote_ip))

      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @remote_ip)
      assert :ok = Account.Public.generate_otp(email, @other_ip)
    end

    test "an email address at its daily total of checks gets no new code anywhere" do
      email = unique_email("locked-total")

      for i <- 1..10, _ <- 1..10, do: assert(check?(email, network_ip(i)))

      assert {:error, :rate_limited} = Account.Public.generate_otp(email, network_ip(11))
    end
  end

  describe "checking codes" do
    test "an email address gets 10 checks per hour from one network address, across its codes" do
      email = unique_email("checks")

      for _ <- 1..2 do
        delete_codes(email)
        {_code, wrong_code} = insert_code(email)

        for _ <- 1..5 do
          assert {:error, :invalid} = Account.Public.verify_otp(email, wrong_code, @remote_ip)
        end
      end

      delete_codes(email)
      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} = Account.Public.verify_otp(email, code, @remote_ip)
      assert Repo.one(AuthCodeModel.active_query(email)).attempts == 0
      assert {:ok, nil} = Account.Public.verify_otp(email, code, @other_ip)
    end

    test "an email address gets 30 checks per day from one network address" do
      email = unique_email("daily")

      for _ <- 1..3 do
        for _ <- 1..10, do: assert(check?(email, @remote_ip))
        end_windows(3600)
      end

      refute check?(email, @remote_ip)
      assert check?(email, @other_ip)

      end_windows(86_400)
      assert check?(email, @remote_ip)
    end

    test "checks from one network address don't lock the email address out on another" do
      user = Factories.insert!(:member)

      for _ <- 1..3 do
        for _ <- 1..2 do
          assert request?(user.email, @other_ip)
          delete_codes(user.email)
          insert_code(user.email, user.id)

          for _ <- 1..5 do
            assert {:error, :invalid} = Account.Public.verify_otp(user.email, "000000", @other_ip)
          end
        end

        end_windows(3600)
      end

      assert {:error, :rate_limited} = Account.Public.generate_otp(user.email, @other_ip)

      assert :ok = Account.Public.generate_otp(user.email, @remote_ip)
      delete_codes(user.email)
      {code, _wrong_code} = insert_code(user.email, user.id)

      assert {:ok, %{id: user_id}} = Account.Public.verify_otp(user.email, code, @remote_ip)
      assert user_id == user.id
    end

    test "an email address gets 100 checks per day across network addresses" do
      email = unique_email("checks-total")

      for i <- 1..10, _ <- 1..10, do: assert(check?(email, network_ip(i)))
      refute check?(email, network_ip(11))

      end_windows(86_400)
      assert check?(email, network_ip(11))
    end

    test "a network address gets 200 checks per hour, for any email addresses" do
      for _ <- 1..200 do
        assert check?(unique_email("network"), @remote_ip)
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
          do: assert(check?(email, @remote_ip))

      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} =
               Account.Public.verify_otp(String.upcase(email), code, @remote_ip)
    end
  end

  describe "totals per email address" do
    test "checks of a code without attempts left leave the totals alone" do
      email = unique_email("used-up")
      {_code, auth_code} = AuthCodeModel.build(email, nil)
      Repo.insert!(%{auth_code | attempts: 5})

      for i <- 1..10, _ <- 1..10 do
        assert {:error, :max_attempts} = Account.Public.verify_otp(email, "000000", network_ip(i))
      end

      delete_codes(email)
      {code, _wrong_code} = insert_code(email)

      assert {:ok, nil} = Account.Public.verify_otp(email, code, network_ip(11))
    end

    test "requests refused by the network address limit leave the totals alone" do
      for _ <- 1..200, do: assert(request?(unique_email("other"), network_ip(1)))

      email = unique_email("refused-requests")
      for _ <- 1..20, do: refute(request?(email, network_ip(1)))

      for i <- 2..6, _ <- 1..10, do: assert(request?(email, network_ip(i)))
    end

    test "checks refused by the network address limit leave the totals alone" do
      for _ <- 1..200, do: assert(check?(unique_email("other"), network_ip(1)))

      email = unique_email("refused-checks")
      {code, _wrong_code} = insert_code(email)

      for _ <- 1..20 do
        assert {:error, :max_attempts} = Account.Public.verify_otp(email, code, network_ip(1))
      end

      assert Repo.one(AuthCodeModel.active_query(email)).attempts == 0
      for i <- 2..11, _ <- 1..10, do: assert(check?(email, network_ip(i)))
    end

    test "filling the check total takes 20 codes checked from 10 network addresses" do
      email = unique_email("filled")

      for i <- 1..10, _ <- 1..2 do
        delete_codes(email)
        {_code, wrong_code} = insert_code(email)

        for _ <- 1..5 do
          assert {:error, :invalid} = Account.Public.verify_otp(email, wrong_code, network_ip(i))
        end
      end

      delete_codes(email)
      {code, _wrong_code} = insert_code(email)

      assert {:error, :max_attempts} = Account.Public.verify_otp(email, code, network_ip(11))
    end

    test "19 codes checked from 10 network addresses leave room in the check total" do
      email = unique_email("not-filled")

      for i <- 1..10, j <- 1..2, {i, j} != {10, 2} do
        delete_codes(email)
        {_code, wrong_code} = insert_code(email)

        for _ <- 1..5 do
          assert {:error, :invalid} = Account.Public.verify_otp(email, wrong_code, network_ip(i))
        end
      end

      delete_codes(email)
      {code, _wrong_code} = insert_code(email)

      assert {:ok, nil} = Account.Public.verify_otp(email, code, network_ip(11))
    end

    test "a check taken back leaves room in the check total" do
      email = unique_email("taken-back")

      for _ <- 1..100, do: assert(AuthCodeLimits.count_check?(email))
      refute AuthCodeLimits.count_check?(email)

      AuthCodeLimits.uncount_check(email)
      AuthCodeLimits.uncount_check(email)
      assert AuthCodeLimits.count_check?(email)
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
