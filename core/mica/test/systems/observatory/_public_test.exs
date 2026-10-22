defmodule Systems.Observatory.PublicTest do
  use Core.DataCase, async: true
  alias Systems.Observatory.Public

  describe "subscribe/1" do
    test "create a subscription" do
      Public.subscribe(:stuff_happened)
    end

    test "create a subscription with a key" do
      Public.subscribe(:stuff_happened, [1, :a])
    end
  end

  describe "dispatch/2" do
    test "dispatch does nothing without subscriptions" do
      Public.dispatch(:stuff_happened, [], %{some: :data})
    end

    test "dispatch sends a message to the subscribed processes" do
      Public.subscribe(:stuff_happened)
      Public.dispatch(:stuff_happened, [], %{some: :data})

      assert Process.info(self(), :messages) ==
               {:messages,
                [
                  %Phoenix.Socket.Broadcast{
                    event: "observation",
                    payload: {:stuff_happened, %{some: :data}},
                    topic: "signal:stuff_happened:"
                  }
                ]}
    end

    test "dispatch to matching key only" do
      Public.subscribe(:stuff_happened, [1])
      # This should not be received by the previous subscription since the key differs
      Public.dispatch(:stuff_happened, [2], %{some: :data})
      assert Process.info(self(), :messages) == {:messages, []}

      # This should be received since the key is the same
      Public.dispatch(:stuff_happened, [1], %{some: :data})

      assert Process.info(self(), :messages) ==
               {:messages,
                [
                  %Phoenix.Socket.Broadcast{
                    event: "observation",
                    payload: {:stuff_happened, %{some: :data}},
                    topic: "signal:stuff_happened:1"
                  }
                ]}
    end
  end

  describe "local_dispatch/2" do
    test "does nothing without subscriptions" do
      Public.dispatch(:stuff_happened, [], %{some: :data})
    end

    test "sends a message to the subscribed processes" do
      Public.subscribe(:stuff_happened)
      Public.local_dispatch(:stuff_happened, [], %{some: :data})

      assert Process.info(self(), :messages) ==
               {:messages,
                [
                  %Phoenix.Socket.Broadcast{
                    event: "observation",
                    payload: {:stuff_happened, %{some: :data}},
                    topic: "signal:stuff_happened:"
                  }
                ]}
    end

    test "to matching key only" do
      Public.subscribe(:stuff_happened, [1])
      # This should not be received by the previous subscription since the key differs
      Public.local_dispatch(:stuff_happened, [2], %{some: :data})
      assert Process.info(self(), :messages) == {:messages, []}

      # This should be received since the key is the same
      Public.local_dispatch(:stuff_happened, [1], %{some: :data})

      assert Process.info(self(), :messages) ==
               {:messages,
                [
                  %Phoenix.Socket.Broadcast{
                    event: "observation",
                    payload: {:stuff_happened, %{some: :data}},
                    topic: "signal:stuff_happened:1"
                  }
                ]}
    end
  end
end
