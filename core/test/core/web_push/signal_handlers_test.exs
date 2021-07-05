defmodule Core.WebPush.SignalHandler.Test do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo
  alias Core.Factories
  alias Core.WebPush.SignalHandlers
  alias Core.WebPush.Worker

  describe "new notification" do
    setup do
      subscription = Factories.insert!(:web_push_subscription)
      user = subscription.user
      box = Factories.insert!(:notification_box, %{user: user})

      {:ok, box: box, user: user, subscription: subscription}
    end

    test "send web-push for new notifications", %{box: box, subscription: subscription} do
      SignalHandlers.dispatch(:new_notification, %{box: box, data: %{title: "Hello Test"}})

      assert_enqueued(
        worker: Worker,
        args: %{subscription: subscription.id, message: "Hello Test"}
      )
    end
  end
end
