defmodule Systems.Notify.Channel.NATest do
  use ExUnit.Case, async: true

  alias Systems.Notify.Channel.NA
  alias Systems.Notify.EventModel

  describe "build_payload/1 :contribution_accepted" do
    test "carries node_id from metadata into params" do
      event = %EventModel{
        type: "contribution_accepted",
        metadata: %{"assignment_id" => 42, "node_id" => 7}
      }

      assert {:ok,
              %{
                "action_module" => "Elixir.Systems.Assignment.NextActions.ContributionReviewed",
                "key" => "42:accepted",
                "params" => %{
                  "assignment_id" => 42,
                  "node_id" => 7,
                  "outcome" => "accepted"
                }
              }} = NA.build_payload(event)
    end

    test "sets node_id nil when metadata does not include it" do
      event = %EventModel{
        type: "contribution_accepted",
        metadata: %{"assignment_id" => 42}
      }

      assert {:ok, %{"params" => %{"node_id" => nil}}} = NA.build_payload(event)
    end
  end

  describe "build_payload/1 :contribution_declined" do
    test "carries node_id from metadata into params" do
      event = %EventModel{
        type: "contribution_declined",
        metadata: %{"assignment_id" => 42, "node_id" => 7}
      }

      assert {:ok,
              %{
                "action_module" => "Elixir.Systems.Assignment.NextActions.ContributionReviewed",
                "key" => "42:declined",
                "params" => %{
                  "assignment_id" => 42,
                  "node_id" => 7,
                  "outcome" => "declined"
                }
              }} = NA.build_payload(event)
    end

    test "sets node_id nil when metadata does not include it" do
      event = %EventModel{
        type: "contribution_declined",
        metadata: %{"assignment_id" => 42}
      }

      assert {:ok, %{"params" => %{"node_id" => nil}}} = NA.build_payload(event)
    end
  end

  describe "build_payload/1 unknown event type" do
    test "returns :skip" do
      event = %EventModel{type: "unknown_event", metadata: %{}}
      assert :skip = NA.build_payload(event)
    end
  end
end
