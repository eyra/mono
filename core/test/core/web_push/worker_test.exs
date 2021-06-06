defmodule Core.WebPush.Worker.Test do
  import Mox
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo
  alias Core.Factories
  alias Core.WebPush.Worker
  alias Core.WebPush.PushSubscription

  setup :verify_on_exit!

  setup do
    user = Factories.insert!(:member)
    subscription = Factories.insert!(:web_push_subscription)
    {:ok, user: user, subscription: subscription}
  end

  test "send a single ok message", %{subscription: subscription} do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 201}} end)

    assert :ok = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
  end

  test "remove subscription on not found / gone" do
    for status_code <- [404, 410] do
      Core.WebPush.MockBackend
      |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: status_code}} end)

      subscription = Factories.insert!(:web_push_subscription)

      assert {:ok, _} = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
      assert Repo.get(PushSubscription, subscription.id) == nil
    end
  end

  test "snooze on rate limit", %{subscription: subscription} do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 429}} end)

    assert {:snooze, _} = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
  end

  test "discard messages that are too large", %{subscription: subscription} do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 413}} end)

    assert {:discard, _} = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
  end

  test "discard messages that are malformed", %{subscription: subscription} do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 400}} end)

    assert {:discard, _} = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
  end

  test "error on other status codes", %{subscription: subscription} do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 418}} end)

    assert {:error, _} = perform_job(Worker, %{subscription: subscription.id, message: "Hello"})
  end
end
