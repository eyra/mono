defmodule Core.WebPushTest do
  use Core.DataCase, async: true
  import ExUnit.CaptureLog
  import Mox
  alias Core.Factories
  alias Core.WebPush

  setup :verify_on_exit!

  setup do
    user = Factories.insert!(:member)
    {:ok, user: user}
  end

  describe "register/2" do
    test "register rejects invalid subscriptions", %{user: user} do
      subscription =
        %{
          "expirationTime" => nil,
          "keys" => %{
            "auth" => "adf",
            "something-else" => "abcde"
          }
        }
        |> Jason.encode!()

      assert {:error, _} = WebPush.register(user, subscription)
    end

    test "register accepts valid subscription", %{user: user} do
      subscription =
        %{
          "endpoint" => "https://example.com/push/send/qwerty1234",
          "expirationTime" => nil,
          "keys" => %{
            "auth" => "qlbEtiId4mHSgnXPB7pPTQ",
            "p256dh" =>
              "BKfP8PDm3qrDizHkeEh5lsHcD155JxsGBCQ9u6Evb2eWwy2jspyfTiWr6hA1-15lgrR1XxkQqPOupU50OOJ_5Fg"
          }
        }
        |> Jason.encode!()

      assert {:ok, _} = WebPush.register(user, subscription)
    end

    test "registering the same endpoint twice updates the auth info", %{user: user} do
      for key <- ["abcde", "fghijk"] do
        subscription =
          %{
            "endpoint" => "https://example.com/push/send/qwerty1234",
            "expirationTime" => nil,
            "keys" => %{
              "auth" => key,
              "p256dh" =>
                "BKfP8PDm3qrDizHkeEh5lsHcD155JxsGBCQ9u6Evb2eWwy2jspyfTiWr6hA1-15lgrR1XxkQqPOupU50OOJ_5Fg"
            }
          }
          |> Jason.encode!()

        {:ok, _} = WebPush.register(user, subscription)
      end

      subscription =
        Repo.get_by(WebPush.PushSubscription, endpoint: "https://example.com/push/send/qwerty1234")

      assert subscription.auth == "fghijk"
    end
  end

  describe "send/2" do
    setup do
      {:ok, subscription: Factories.insert!(:web_push_subscription)}
    end

    test "send a single ok message", %{subscription: subscription} do
      Core.WebPush.MockBackend
      |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 201}} end)

      assert WebPush.send(subscription.user, "Hello") == :ok
    end

    test "log error responses", %{subscription: subscription} do
      for status_code <- [400, 413, 429, 999] do
        Core.WebPush.MockBackend
        |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: status_code}} end)

        assert capture_log(fn -> :ok = WebPush.send(subscription.user, "Hello") end) =~
                 "Error when sending"
      end
    end

    test "log error when http connection fails", %{subscription: subscription} do
      Core.WebPush.MockBackend
      |> expect(:send_web_push, fn _sub, _message -> {:error, "Some reason"} end)

      assert capture_log(fn -> :ok = WebPush.send(subscription.user, "Hello") end) =~
               "Error when sending"
    end

    test "remove subscription on not found / gone" do
      for status_code <- [404, 410] do
        Core.WebPush.MockBackend
        |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: status_code}} end)

        subscription = Factories.insert!(:web_push_subscription)

        :ok = WebPush.send(subscription.user, "Hello")
        assert Repo.get(WebPush.PushSubscription, subscription.id) == nil
      end
    end
  end
end
