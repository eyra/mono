defmodule Systems.Notify.DispatcherTest do
  use Mica.DataCase, async: false

  alias Mica.Factories
  alias Mica.Repo
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

    test "stamps dispatched_at on the event", %{event: event} do
      assert Repo.reload!(event).dispatched_at != nil
    end
  end
end
