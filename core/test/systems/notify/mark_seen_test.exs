defmodule Systems.Notify.MarkSeenTest do
  use Core.DataCase, async: false

  alias Core.Factories
  alias Core.Repo
  alias Systems.NextAction
  alias Systems.Notify

  describe "mark_seen/2 by correlation_id" do
    setup do
      user = Factories.insert!(:member)

      {:ok, event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 42},
          correlation_id: "participation:7"
        })

      %{user: user, event: event}
    end

    test "flips every message for that correlation to :seen with a timestamp", %{
      user: user,
      event: event
    } do
      {:ok, count} = Notify.Public.mark_seen(user, correlation_id: "participation:7")

      # Two channels for this event type → two messages marked
      assert count == 2

      messages =
        Notify.MessageModel
        |> Repo.all()
        |> Enum.filter(&(&1.event_id == event.id))

      assert Enum.all?(messages, &(&1.status == :seen))
      assert Enum.all?(messages, &(&1.seen_at != nil))
    end

    test "is idempotent — a second call marks zero", %{user: user} do
      {:ok, first} = Notify.Public.mark_seen(user, correlation_id: "participation:7")
      {:ok, second} = Notify.Public.mark_seen(user, correlation_id: "participation:7")

      assert first == 2
      assert second == 0
    end

    test "leaves messages for other correlations alone", %{user: user, event: event} do
      {:ok, _other_event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 99},
          correlation_id: "participation:99"
        })

      {:ok, _} = Notify.Public.mark_seen(user, correlation_id: "participation:7")

      # Only the messages for event 7 are :seen; event 99's are still :sent
      messages_by_event =
        Notify.MessageModel
        |> Repo.all()
        |> Enum.group_by(& &1.event_id)

      for msg <- messages_by_event[event.id], do: assert(msg.status == :seen)

      other_id = Enum.find(Map.keys(messages_by_event), &(&1 != event.id))
      for msg <- messages_by_event[other_id], do: assert(msg.status == :sent)
    end
  end

  describe "mark_seen/2 by event_types" do
    test "matches messages by event type regardless of correlation" do
      user = Factories.insert!(:member)

      {:ok, _accepted} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_accepted,
          subject_user: user,
          metadata: %{"assignment_id" => 1},
          correlation_id: "participation:1"
        })

      {:ok, _declined} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_declined,
          subject_user: user,
          metadata: %{"assignment_id" => 2},
          correlation_id: "participation:2"
        })

      # Only accepted-type messages should get :seen
      {:ok, count} = Notify.Public.mark_seen(user, event_types: [:contribution_accepted])

      # Two channels for the accepted event
      assert count == 2

      accepted_messages =
        Notify.MessageModel
        |> Repo.all()
        |> Enum.filter(fn m ->
          event = Repo.get!(Notify.EventModel, m.event_id)
          event.type == "contribution_accepted"
        end)

      assert Enum.all?(accepted_messages, &(&1.status == :seen))
    end
  end

  describe "NA channel side effect" do
    test "clears the NBA on the recipient's inbox when messages are marked seen" do
      user = Factories.insert!(:member)

      {:ok, _event} =
        Notify.Public.record_event(%Notify.EventAttrs{
          type: :contribution_declined,
          subject_user: user,
          metadata: %{"assignment_id" => 42},
          correlation_id: "participation:7"
        })

      # After record_event, the NA channel created the NBA
      assert nba_exists?(user, "42:declined")

      {:ok, _} = Notify.Public.mark_seen(user, correlation_id: "participation:7")

      # NA channel's mark_seen ran → NBA cleared
      refute nba_exists?(user, "42:declined")
    end
  end

  defp nba_exists?(%{id: user_id}, key) do
    import Ecto.Query

    Repo.exists?(from(na in NextAction.Model, where: na.user_id == ^user_id and na.key == ^key))
  end
end
