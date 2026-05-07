defmodule Observatory.TestHelper do
  @moduledoc """
  Test helpers for verifying Observatory updates in tests.

  Since Observatory updates are now collected during transactions and committed
  with Repo.commit(), we need different assertion patterns than signal testing.
  """

  import ExUnit.Assertions
  alias Systems.Observatory

  @doc """
  Asserts that Observatory updates were collected and committed.

  This checks that:
  1. Updates were collected during the transaction
  2. They were dispatched (Process dictionary was cleared)

  Note: This only works if called in the same process that ran the transaction.

  ## Examples

      test "update_user_profile dispatches updates" do
        assert_observatory_committed fn ->
          Account.Public.update_user_profile(user_changeset, profile_changeset)
        end
      end
  """
  defmacro assert_observatory_committed(fun) do
    quote do
      # Ensure we start with no collected updates
      Observatory.UpdateCollector.clear()

      # Run the function
      result = unquote(fun).()

      # After Repo.commit(), updates should be dispatched (Process dict cleared)
      assert Observatory.UpdateCollector.count() == 0,
             "Expected Observatory updates to be committed and cleared, but #{Observatory.UpdateCollector.count()} updates remain"

      result
    end
  end

  @doc """
  Asserts that a specific number of Observatory updates were collected.

  Useful for testing that updates are being collected before commit.

  ## Examples

      test "multiple updates are collected" do
        Multi.new()
        |> Multi.insert(:item1, changeset1)
        |> Signal.Public.multi_dispatch({:item, :created})
        |> Multi.insert(:item2, changeset2)
        |> Signal.Public.multi_dispatch({:item, :created})
        |> Repo.transaction()  # Don't use commit to keep updates

        assert_observatory_collected(2)
      end
  """
  def assert_observatory_collected(expected_count) do
    actual_count = Observatory.UpdateCollector.count()

    assert actual_count == expected_count,
           "Expected #{expected_count} Observatory updates collected, got #{actual_count}"
  end

  @doc """
  Asserts that no Observatory updates are currently collected.

  ## Examples

      test "error case clears updates" do
        # ... run code that might collect updates ...
        assert_no_observatory_collected()
      end
  """
  def assert_no_observatory_collected do
    assert_observatory_collected(0)
  end

  @doc """
  Captures Observatory dispatches for testing.

  Since Observatory.Public.dispatch sends to PubSub, we can subscribe
  and capture the messages for assertions.

  ## Examples

      test "update dispatches to correct LiveView" do
        capture_observatory_dispatch({:embedded_live_view, MyView}, [model.id]) do
          Account.Public.update_user_profile(user_changeset, profile_changeset)
        end
      end
  """
  def capture_observatory_dispatch(expected_target, expected_args, fun) do
    # Subscribe to the Observatory topic
    {_target_type, target_module} = expected_target
    Observatory.Public.subscribe(target_module, expected_args)

    # Run the function
    result = fun.()

    # Assert we received the broadcast
    assert_receive %Phoenix.Socket.Broadcast{
                     event: "observation",
                     payload: {^target_module, _message},
                     topic: _topic
                   },
                   1000,
                   "Expected Observatory dispatch for #{inspect(expected_target)} with args #{inspect(expected_args)}"

    result
  end

  @doc """
  Clears any collected Observatory updates.

  Useful in test setup/cleanup.

  ## Examples

      setup do
        Observatory.TestHelper.clear_collected()
        :ok
      end
  """
  def clear_collected do
    Observatory.UpdateCollector.clear()
  end
end
