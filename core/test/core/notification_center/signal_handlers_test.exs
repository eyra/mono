defmodule Core.NotificationCenter.SignalHandlersTest do
  use Core.DataCase, async: true
  import Core.Signals.Test
  alias Core.Factories
  alias Core.NotificationCenter.SignalHandlers

  describe "promotion_published" do
    setup do
      {:ok, student: Factories.insert!(:member, %{student: true})}
    end

    test "create notification when a promotion is published", %{student: student} do
      box = Core.NotificationCenter.get_or_create_box(student)

      promotion =
        Factories.insert!(:promotion, %{
          study: Factories.insert!(:study),
          parent_content_node: Factories.insert!(:content_node)
        })

      SignalHandlers.dispatch(:promotion_published, %{promotion: promotion})

      message = assert_signal_dispatched(:new_notification)
      assert message.data.title == "New study available"
      assert message.box.id == box.id
    end

    test "only send the notification once" do
      promotion =
        Factories.insert!(:promotion, %{
          study: Factories.insert!(:study),
          parent_content_node: Factories.insert!(:content_node)
        })

      SignalHandlers.dispatch(:promotion_published, %{promotion: promotion})

      # Clear out the messages
      assert_signal_dispatched(:new_notification)

      # Retracting and publishing the same promotion again will not trigger a
      # notification.
      SignalHandlers.dispatch(:promotion_published, %{promotion: promotion})

      refute_signal_dispatched(:new_notification)
    end
  end
end
