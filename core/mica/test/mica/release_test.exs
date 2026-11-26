defmodule Mica.ReleaseTest do
  use Mica.DataCase, async: false

  import ExUnit.CaptureIO

  alias Systems.License

  @email Mica.Release.test_user_email()

  # A release task (`bin/core eval`) starts no apps, so Timex never sets the time
  # zone database there; the app config does, for license end dates in Amsterdam.
  test "the time zone database comes from the app config, not from Timex's start" do
    assert Calendar.get_time_zone_database() == Tzdata.TimeZoneDatabase
  end

  describe "seed_test_user/0" do
    defp seed, do: capture_io(fn -> Mica.Release.seed_test_user() end)

    defp test_user, do: Mica.Repo.get_by!(Systems.Account.User, email: @email)

    test "creates the test creator with a Publish license" do
      seed()

      assert License.Public.active?(test_user(), :publish)
    end

    test "gives an existing test creator whose Publish license ended a new one" do
      user = Factories.insert!(:creator, %{email: @email})

      Factories.insert!(:license, %{user: user, valid_until: Date.add(License.Public.today(), -1)})

      seed()

      assert License.Public.active?(user, :publish)
    end

    test "gives an existing test creator without a license one" do
      user = Factories.insert!(:creator, %{email: @email})

      seed()

      assert License.Public.active?(user, :publish)
    end

    test "leaves a Publish license that hasn't ended as it is" do
      user = Factories.insert!(:creator, %{email: @email})
      Factories.insert!(:license, %{user: user})

      seed()

      assert [_] = License.Public.list_records(user)
    end
  end
end
