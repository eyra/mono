defmodule Core.Mailer.SignalHandlers.Test do
  use Core.DataCase, async: true
  use Bamboo.Test
  alias Core.Factories
  alias Core.Mailer.SignalHandlers

  describe "dispatch :new_notification" do
    setup do
      user = Factories.insert!(:member)
      box = Factories.insert!(:notification_box, %{user: user})

      {:ok, box: box, user: user}
    end

    test "send mail to user", %{box: box, user: _user} do
      SignalHandlers.dispatch(:new_notification, %{box: box, data: %{title: "Hello Test Message"}})

      assert_email_delivered_with(text_body: ~r/Test Message/)
    end
  end
end
