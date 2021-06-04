defmodule Core.WebPush.SignalHandler.Test do
  use Core.DataCase, async: true
  import Mox
  alias Core.Factories
  alias Core.WebPush.SignalHandlers

  setup :verify_on_exit!

  describe "new notification" do
    setup do
      subscription = Factories.insert!(:web_push_subscription)
      user = subscription.user
      box = Factories.insert!(:notification_box, %{user: user})

      {:ok, box: box, user: user}
    end

    test "send web-push for new notifications", %{box: box} do
      mock_push()
      SignalHandlers.dispatch(:new_notification, %{box: box, data: %{title: "Hello Test"}})
    end
  end

  defp mock_push do
    Core.WebPush.MockBackend
    |> expect(:send_web_push, fn _sub, _message -> {:ok, %{status_code: 201}} end)
  end
end
