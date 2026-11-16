defmodule MicaSaas.Systems.Notify.MarkSeenTest do
  use Mica.DataCase, async: false

  alias Mica.Factories
  alias Mica.Repo

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
end
