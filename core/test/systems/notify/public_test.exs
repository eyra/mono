defmodule Systems.Notify.PublicTest do
  use Core.DataCase, async: false

  alias Core.Factories
  alias Core.Repo
  alias Systems.Notify

  describe "record_event/1" do
    setup do
      user = Factories.insert!(:member)
      %{user: user}
    end

    test "persists the event with the supplied attrs", %{user: user} do
      assert {:ok, event} =
               Notify.Public.record_event(%Notify.EventAttrs{
                 type: :contribution_accepted,
                 subject_user: user,
                 metadata: %{"assignment_id" => 42},
                 correlation_id: "participation:7",
                 source: __MODULE__
               })

      assert event.type == "contribution_accepted"
      assert event.subject_user_id == user.id
      assert event.metadata == %{"assignment_id" => 42}
      assert event.correlation_id == "participation:7"
      # source: module atom persisted as its inspect string
      assert event.source == inspect(__MODULE__)
    end

    test "hands the event to the scheduler — dispatched_at is stamped", %{user: user} do
      {:ok, event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user
        })

      # Re-read: record_event returns the pre-dispatch struct
      reloaded = Repo.reload!(event)
      assert reloaded.dispatched_at
    end

    test "rejects unknown event types", %{user: user} do
      assert {:error, {:unknown_event_type, "totally_made_up"}} =
               Notify.Public.record_event(%Notify.EventAttrs{
                 type: :totally_made_up,
                 subject_user: user
               })
    end

    test "requires subject_user at struct construction time" do
      assert_raise ArgumentError, fn ->
        struct!(Notify.EventAttrs, type: :contribution_accepted)
      end
    end
  end
end
