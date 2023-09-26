defmodule Core.APNS.SignalHandlers.Test do
  use Core.DataCase, async: true
  import Mox
  alias Core.Factories
  alias Core.APNS.SignalHandlers
  alias Core.APNS

  setup :verify_on_exit!

  describe "dispatch :new_notification" do
    setup do
      user = Factories.insert!(:member)
      box = Factories.insert!(:notification_box, %{user: user})
      APNS.register(user, "a")

      {:ok, box: box, user: user}
    end

    test "send notification to user", %{box: box} do
      Core.APNS.MockBackend
      |> expect(:send_notification, fn _notif -> :ok end)

      SignalHandlers.intercept(:new_notification, %{
        box: box,
        data: %{title: "Hello Test Message"}
      })
    end
  end
end
