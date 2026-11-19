defmodule MicaSaas.Systems.Account.AuthCodeLimitsTest do
  use Mica.DataCase, async: true

  import Ecto.Query

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Account
  alias Systems.Account.AuthCodeLimits
  alias Systems.Account.AuthCodeModel
  alias Systems.Rate
  alias Systems.Rate.CounterModel

  @remote_ip "203.0.113.10"
  @other_ip "198.51.100.20"

  # The limits count per hour and per day, and a day starts on the hour.
  setup do: Rate.TestHelper.wait_out_window_end(3600)

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

  # A request or check as `Account.Public` counts it, without the per-minute
  # quota per email address that the service keeps in memory.
  defp request?(email, remote_ip),
    do: AuthCodeLimits.allow_request?(email, remote_ip) and AuthCodeLimits.count_request?(email)

  defp check?(email, remote_ip),
    do: AuthCodeLimits.allow_check?(email, remote_ip) and AuthCodeLimits.count_check?(email)

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
    test "a network address gets 200 codes per hour, for any email addresses" do
      for _ <- 1..200 do
        assert request?(unique_email("network"), @remote_ip)
      end

      email = unique_email("network")
      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @remote_ip)
      assert Repo.one(AuthCodeModel.active_query(email)) == nil

      assert :ok = Account.Public.generate_otp(email, @other_ip)
    end

    test "an email address that can't check codes from a network address gets no new code there" do
      email = unique_email("locked")

      for _ <- 1..10, do: assert(check?(email, @remote_ip))

      assert {:error, :rate_limited} = Account.Public.generate_otp(email, @remote_ip)
      assert :ok = Account.Public.generate_otp(email, @other_ip)
    end
  end

  describe "checking codes" do
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
  end
end
