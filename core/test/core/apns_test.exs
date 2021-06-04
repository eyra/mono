defmodule Core.APNSTest do
  use Core.DataCase, async: true
  import Mox
  import ExUnit.CaptureLog
  alias Core.APNS
  alias Core.Factories

  @valid_token %{device_token: "some device_token"}

  setup :verify_on_exit!

  setup do
    {:ok, user: Factories.insert!(:member)}
  end

  describe "get_push_tokens/1" do
    test "always returns a list for a given user", %{user: user} do
      assert APNS.get_push_tokens(user) == []
    end

    test "returns a list of registered tokens", %{user: user} do
      {:ok, _} = APNS.register(user, "a")
      {:ok, _} = APNS.register(user, "b")
      assert APNS.get_push_tokens(user) |> Enum.map(& &1.device_token) == ["a", "b"]
    end
  end

  describe "register/2" do
    test "allows device tokens", %{user: user} do
      {:ok, _} = APNS.register(user, "a")
    end

    test "allows registering the same device token twice", %{user: user} do
      {:ok, _} = APNS.register(user, "a")
      {:ok, _} = APNS.register(user, "a")
      # there is still one registration
      assert APNS.get_push_tokens(user) |> Enum.map(& &1.device_token) == ["a"]
    end
  end

  describe "send_notification/2" do
    test "send a notification", %{user: user} do
      Core.APNS.MockBackend
      |> expect(:send_notification, fn _notif -> :ok end)

      {:ok, _} = APNS.register(user, "a")
      assert APNS.send_notification(user, "Hello World") == :ok
    end

    test "device tokens are removed when they are invalid", %{user: user} do
      Core.APNS.MockBackend
      |> expect(:send_notification, fn _notif ->
        %{device_token: "a", response: :bad_device_token}
      end)

      {:ok, _} = APNS.register(user, "a")
      APNS.send_notification(user, "Hello World")
      # The token should have been removed
      assert APNS.get_push_tokens(user) == []
    end

    test "log other errors", %{user: user} do
      Core.APNS.MockBackend
      |> expect(:send_notification, fn _notif ->
        %{
          device_token: "a",
          response: :missing_device_token
        }
      end)

      {:ok, _} = APNS.register(user, "a")

      assert capture_log(fn ->
               APNS.send_notification(user, "Hello World")
             end) =~ "Unexpected push error:"

      assert APNS.get_push_tokens(user) |> Enum.map(& &1.device_token) == ["a"]
    end
  end
end
