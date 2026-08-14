defmodule Systems.Notify.DispatcherTest do
  use Core.DataCase, async: false

  alias Core.Factories
  alias Core.Repo
  alias Systems.Notify

  describe "dispatch/1" do
    setup do
      user = Factories.insert!(:member)

      {:ok, event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 42, "assignment_title" => "Test study"}
        })

      %{user: user, event: event}
    end

    test "creates one message per configured channel", %{event: event} do
      messages =
        Notify.MessageModel
        |> Repo.all()
        |> Enum.filter(&(&1.event_id == event.id))

      channels = messages |> Enum.map(& &1.channel) |> Enum.sort()
      assert channels == [:email, :na]
    end

    test "each message ends up in :sent status after delivery", %{event: event} do
      messages =
        Notify.MessageModel
        |> Repo.all()
        |> Enum.filter(&(&1.event_id == event.id))

      assert Enum.all?(messages, &(&1.status == :sent))
      assert Enum.all?(messages, &(&1.delivered_at != nil))
      assert Enum.all?(messages, &(&1.attempts == 1))
    end

    test "stamps dispatched_at on the event", %{event: event} do
      assert Repo.reload!(event).dispatched_at != nil
    end
  end
end
