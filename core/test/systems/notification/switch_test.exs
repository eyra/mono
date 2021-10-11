defmodule Systems.Notification.SwitchTest do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper
  alias Core.Factories
  alias Systems.Notification

  describe "submission_published" do
    setup do
      {:ok, student: Factories.insert!(:member, %{student: true})}
    end

    test "create notification when a submission is accepted", %{student: student} do
      box = Notification.Context.get_or_create_box(student)

      promotion =
        Factories.insert!(:promotion, %{
          study: Factories.insert!(:study),
          parent_content_node: Factories.insert!(:content_node)
        })

      Notification.Switch.dispatch(:submission_accepted, %{submission: promotion.submission})

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

      Notification.Switch.dispatch(:submission_accepted, %{submission: promotion.submission})

      # Clear out the messages
      assert_signal_dispatched(:new_notification)

      # Retracting and publishing the same promotion again will not trigger a
      # notification.
      Notification.Switch.dispatch(:submission_accepted, %{submission: promotion.submission})

      refute_signal_dispatched(:new_notification)
    end
  end
end
