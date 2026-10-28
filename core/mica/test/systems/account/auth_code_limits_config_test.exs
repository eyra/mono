defmodule Systems.Account.AuthCodeLimitsConfigTest do
  # Sets the limit overrides in the application environment.
  use Core.DataCase, async: false

  alias Systems.Account.AuthCodeLimits

  @remote_ip "203.0.113.10"

  setup do
    original = Core.Env.get(:auth_code_limits)

    on_exit(fn ->
      if original,
        do: Core.Env.put(:auth_code_limits, original),
        else: Application.delete_env(:core, :auth_code_limits)
    end)
  end

  defp override(limits) do
    Core.Env.put(:auth_code_limits, overrides: AuthCodeLimits.overrides!(limits))
  end

  test "without overrides the default limits apply" do
    for _ <- 1..10, do: assert(AuthCodeLimits.allow_request?("a@example.com", @remote_ip))
    refute AuthCodeLimits.allow_request?("a@example.com", @remote_ip)
  end

  test "an override replaces the default limit of its action and count" do
    override([
      %{"action" => "request", "by" => "email_network", "limit" => 2, "window" => "hour"}
    ])

    assert AuthCodeLimits.allow_request?("a@example.com", @remote_ip)
    assert AuthCodeLimits.allow_request?("a@example.com", @remote_ip)
    refute AuthCodeLimits.allow_request?("a@example.com", @remote_ip)
  end

  test "an override keeps the other windows of its action and count" do
    override([
      %{"action" => "check", "by" => "email_network", "limit" => 20, "window" => "hour"}
    ])

    assert [{:check, :email_network, 30, :day}, {:check, :email_network, 20, :hour}] =
             Enum.filter(AuthCodeLimits.limits(), &match?({:check, :email_network, _, _}, &1))
  end

  test "an override with a window that has no default adds a limit" do
    override([
      %{"action" => "request", "by" => "email_network", "limit" => 3, "window" => "minute"}
    ])

    assert [{:request, :email_network, 10, :hour}, {:request, :email_network, 3, :minute}] =
             Enum.filter(AuthCodeLimits.limits(), &match?({:request, :email_network, _, _}, &1))
  end

  test "an override replaces the daily total of an email address" do
    override([%{"action" => "check", "by" => "email", "limit" => 150, "window" => "day"}])

    assert [{:check, :email, 150, :day}] =
             Enum.filter(AuthCodeLimits.limits(), &match?({:check, :email, _, _}, &1))
  end

  test "an override leaves the other defaults in place" do
    override([%{"action" => "check", "by" => "network", "limit" => 500, "window" => "hour"}])

    assert {:request, :network, 200, :hour} in AuthCodeLimits.limits()
    assert {:check, :network, 500, :hour} in AuthCodeLimits.limits()
  end

  describe "overrides!/1" do
    test "raises on an unknown action" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([
          %{"action" => "verify", "by" => "email", "limit" => 2, "window" => "hour"}
        ])
      end
    end

    test "raises on an unknown window" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([
          %{"action" => "check", "by" => "email", "limit" => 2, "window" => "week"}
        ])
      end
    end

    test "raises without a limit" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([%{"action" => "check", "by" => "email", "window" => "hour"}])
      end
    end

    test "raises on a limit of 0" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([
          %{"action" => "check", "by" => "email", "limit" => 0, "window" => "hour"}
        ])
      end
    end

    test "raises on a negative limit" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([
          %{"action" => "check", "by" => "email", "limit" => -5, "window" => "hour"}
        ])
      end
    end

    test "raises on a limit that is a string" do
      assert_raise RuntimeError, fn ->
        AuthCodeLimits.overrides!([
          %{"action" => "check", "by" => "email", "limit" => "20abc", "window" => "hour"}
        ])
      end
    end
  end
end
