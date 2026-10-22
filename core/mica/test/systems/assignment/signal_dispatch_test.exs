defmodule Systems.Assignment.SignalDispatchTest do
  use Core.DataCase, async: false

  alias Frameworks.Signal
  alias Systems.Assignment

  describe "page signal dispatching" do
    setup do
      # Don't isolate signals - we want to test the actual dispatch chain
      :ok
    end

    test "Assignment.Switch dispatches ContentPage signals to Systems.Observatory" do
      # Create a minimal assignment
      assignment = Factories.insert!(:assignment)

      result =
        Signal.Public.dispatch(
          {:page, Assignment.ContentPage},
          %{id: assignment.id, model: assignment, from_pid: self()}
        )

      # The signal should be handled by Systems.Observatory.Switch
      refute match?({:error, :unhandled_signal}, result)
    end

    test "Assignment.Switch dispatches CrewPage signals to Systems.Observatory" do
      # Create a minimal assignment
      assignment = Factories.insert!(:assignment)

      result =
        Signal.Public.dispatch(
          {:page, Assignment.CrewPage},
          %{id: assignment.id, model: assignment, from_pid: self()}
        )

      # The signal should be handled by Systems.Observatory.Switch
      refute match?({:error, :unhandled_signal}, result)
    end

    test "compare module name formats" do
      # Test if they're equal
      assert Assignment.ContentPage == Systems.Assignment.ContentPage
      assert Assignment.ContentPage == :"Elixir.Systems.Assignment.ContentPage"
    end
  end
end
