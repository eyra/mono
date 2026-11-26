defmodule Systems.Notify.DeclaredNextActionTest do
  @moduledoc """
  An event whose declaration names its next action (`next_action:` in
  `Systems.Notify.EventDeclaration`) is shown on the Actions channel (`:na`)
  as that next action, built from the event. Uses License's declarations.
  """
  use Mica.DataCase, async: false

  alias Systems.NextAction
  alias Systems.Notify
  alias Systems.Notify.Channel.NA
  alias Systems.Notify.EventModel

  defp record(user, type, metadata) do
    Notify.Public.record_event(%Notify.EventAttrs{
      type: type,
      subject_user: user,
      correlation_id: "license:publish",
      metadata: metadata
    })
  end

  describe "EventType.options_for/1" do
    test "has the options the event is declared with" do
      assert Notify.EventType.options_for(:license_reminder)[:next_action] ==
               Systems.License.NextActions.Reminder
    end

    test "is empty for an unknown event type" do
      assert Notify.EventType.options_for("unknown_event") == []
    end
  end

  describe "NA.build_payload/1" do
    test "names the declared next action, keyed by the correlation, with the metadata as params" do
      event = %EventModel{
        type: "license_given",
        correlation_id: "license:publish",
        metadata: %{"license" => "publish", "valid_until" => "2027-11-26"}
      }

      assert {:ok,
              %{
                "action_module" => "Elixir.Systems.License.NextActions.Given",
                "key" => "license:publish",
                "params" => %{"license" => "publish", "valid_until" => "2027-11-26"},
                "priority" => "normal"
              }} = NA.build_payload(event)
    end

    test "carries the declared priority" do
      event = %EventModel{type: "license_reminder", correlation_id: "x", metadata: %{}}

      assert {:ok, %{"priority" => "high"}} = NA.build_payload(event)
    end
  end

  describe "delivery on the Actions channel" do
    test "creates the next action with the notification's message in its params" do
      user = Factories.insert!(:creator)

      {:ok, _} =
        record(user, :license_given, %{"license" => "publish", "valid_until" => "2027-11-26"})

      [message] = Repo.all(Notify.MessageModel)

      assert [%NextAction.Model{key: "license:publish", params: params, priority: :normal}] =
               Repo.all(NextAction.Model)

      assert params["notify_message_id"] == message.id
      assert params["valid_until"] == "2027-11-26"
    end

    test "creates it with the declared priority" do
      user = Factories.insert!(:creator)

      {:ok, _} =
        record(user, :license_reminder, %{"license" => "publish", "valid_until" => "2026-12-10"})

      assert [%NextAction.Model{priority: :high}] = Repo.all(NextAction.Model)
    end

    test "marking it seen clears the next action and keeps the notification" do
      user = Factories.insert!(:creator)

      {:ok, _} =
        record(user, :license_given, %{"license" => "publish", "valid_until" => "2027-11-26"})

      {:ok, 1} = Notify.Public.mark_seen(user, correlation_id: "license:publish")

      assert Repo.all(NextAction.Model) == []

      assert [%Notify.MessageModel{status: :seen, seen_at: %DateTime{}}] =
               Repo.all(Notify.MessageModel)
    end
  end

  describe "list_recorded/2" do
    test "has the events of the type and correlation, also seen ones" do
      user = Factories.insert!(:creator)
      {:ok, _} = record(user, :license_ended, %{"valid_until" => "2026-11-25"})
      {:ok, _} = Notify.Public.mark_seen(user, correlation_id: "license:publish")
      user_id = user.id

      assert [%{subject_user_id: ^user_id, metadata: %{"valid_until" => "2026-11-25"}}] =
               Notify.Public.list_recorded(:license_ended, "license:publish")
    end

    test "leaves out other types" do
      user = Factories.insert!(:creator)
      {:ok, _} = record(user, :license_ended, %{"valid_until" => "2026-11-25"})

      assert Notify.Public.list_recorded(:license_reminder, "license:publish") == []
    end
  end
end
