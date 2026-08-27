defmodule Systems.Notify.EventTypeTest do
  use ExUnit.Case, async: false

  alias Systems.Notify.EventType

  setup do
    # Ensure the persistent_term cache is fresh — other tests may have primed it
    on_exit(fn -> EventType.reset() end)
    EventType.reset()
    :ok
  end

  test "channels_for/1 reads from configured notifiers" do
    assert EventType.channels_for(:contribution_accepted) == [:email, :na]
    assert EventType.channels_for(:contribution_declined) == [:email, :na]
    assert EventType.channels_for("contribution_accepted") == [:email, :na]
  end

  test "known?/1 returns true for declared event types" do
    assert EventType.known?(:contribution_accepted)
    assert EventType.known?("contribution_declined")
  end

  test "known?/1 returns false for undeclared event types" do
    refute EventType.known?(:nope)
    refute EventType.known?("nope")
  end

  test "all/0 lists declared event types" do
    types = MapSet.new(EventType.all())
    assert MapSet.subset?(MapSet.new(["contribution_accepted", "contribution_declined"]), types)
  end
end
