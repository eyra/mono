defmodule Systems.Payment.ReconciliationTest do
  @moduledoc """
  The guarded provider calls every reconciler funnels through: back-off on
  retryable provider failures, and the circuit breaker that stops a sweep from
  hammering an outage.

  The reconcilers reach the provider only via `get_withdrawal/2` and
  `get_transaction/2`, so the private back-off is exercised through those.
  Retry counts are asserted with Mox arities — `verify_on_exit!` fails the test
  if the provider was called more or fewer times than declared.
  """
  use Core.DataCase, async: true
  import Mox

  alias Systems.Payment.Error
  alias Systems.Payment.ProviderMock
  alias Systems.Payment.Reconciliation
  alias Systems.Payment.ReconciliationState, as: State

  setup :verify_on_exit!

  # @max_retries 2 in the source: one initial call plus two retries.
  @attempts_before_giving_up 3
  @retryable_statuses [429, 500, 502, 503, 504]

  defp provider_error(status),
    do: {:error, %Error{code: :provider_error, message: "boom", details: %{status: status}}}

  defp withdrawal, do: {:ok, %{uid: "w_1", status: :completed, raw_status: "completed"}}

  describe "get_withdrawal/2 back-off" do
    for status <- @retryable_statuses do
      test "retries a #{status} and returns the eventual success" do
        expect(ProviderMock, :get_withdrawal, fn "w_1" -> provider_error(unquote(status)) end)
        expect(ProviderMock, :get_withdrawal, fn "w_1" -> withdrawal() end)

        assert {{:ok, _}, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
      end
    end

    test "gives up after the retry budget and surfaces the error" do
      expect(ProviderMock, :get_withdrawal, @attempts_before_giving_up, fn "w_1" ->
        provider_error(503)
      end)

      assert {{:error, %Error{}}, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "does not retry a non-retryable status" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" -> provider_error(400) end)

      assert {{:error, %Error{}}, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "does not retry an error carrying no HTTP status" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" ->
        {:error, %Error{code: :connection_error, message: "boom"}}
      end)

      assert {{:error, %Error{}}, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "a retried call that ends in success does not count as a failure" do
      expect(ProviderMock, :get_withdrawal, fn "w_1" -> provider_error(429) end)
      expect(ProviderMock, :get_withdrawal, fn "w_1" -> withdrawal() end)

      assert {_, %State{consecutive_failures: 0}} =
               Reconciliation.get_withdrawal(State.new(), "w_1")
    end
  end

  describe "get_transaction/2 back-off" do
    test "retries a retryable status too: both provider calls share the guard" do
      expect(ProviderMock, :get_transaction, fn "tx_1" -> provider_error(429) end)
      expect(ProviderMock, :get_transaction, fn "tx_1" -> {:ok, %{uid: "tx_1"}} end)

      assert {{:ok, _}, %State{}} = Reconciliation.get_transaction(State.new(), "tx_1")
    end

    test "gives up after the same retry budget" do
      expect(ProviderMock, :get_transaction, @attempts_before_giving_up, fn "tx_1" ->
        provider_error(500)
      end)

      assert {{:error, %Error{}}, %State{}} = Reconciliation.get_transaction(State.new(), "tx_1")
    end
  end

  describe "circuit breaker" do
    test "records a failure on a provider error" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" -> provider_error(400) end)

      assert {_, %State{consecutive_failures: 1}} =
               Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "opens after five consecutive failed lookups" do
      expect(ProviderMock, :get_withdrawal, 5, fn "w_1" -> provider_error(400) end)

      state =
        Enum.reduce(1..5, State.new(), fn _, state ->
          {_, state} = Reconciliation.get_withdrawal(state, "w_1")
          state
        end)

      assert State.circuit_open?(state)
    end

    test "skips the provider entirely once open" do
      open_state = %State{State.new() | circuit_open: true}

      assert {:circuit_open, ^open_state} = Reconciliation.get_withdrawal(open_state, "w_1")
    end

    test "skips get_transaction once open too" do
      open_state = %State{State.new() | circuit_open: true}

      assert {:circuit_open, ^open_state} = Reconciliation.get_transaction(open_state, "tx_1")
    end

    test "a success resets the failure run" do
      expect(ProviderMock, :get_withdrawal, fn "w_1" -> provider_error(400) end)
      expect(ProviderMock, :get_withdrawal, fn "w_1" -> withdrawal() end)

      {_, state} = Reconciliation.get_withdrawal(State.new(), "w_1")
      assert %State{consecutive_failures: 1} = state

      assert {_, %State{consecutive_failures: 0}} = Reconciliation.get_withdrawal(state, "w_1")
    end
  end

  describe "not-found classification" do
    test "a :not_found error code is reported as :not_found" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" ->
        {:error, %Error{code: :not_found, message: "gone"}}
      end)

      assert {:not_found, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "a 404 is reported as :not_found" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" -> provider_error(404) end)

      assert {:not_found, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "a missing record is a healthy provider answer, so it does not trip the breaker" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" ->
        {:error, %Error{code: :not_found, message: "gone"}}
      end)

      assert {:not_found, %State{consecutive_failures: 0}} =
               Reconciliation.get_withdrawal(State.new(), "w_1")
    end

    test "a 404 is not retried: the answer will not change" do
      expect(ProviderMock, :get_withdrawal, 1, fn "w_1" -> provider_error(404) end)

      assert {:not_found, %State{}} = Reconciliation.get_withdrawal(State.new(), "w_1")
    end
  end

  describe "new_state/0" do
    test "hands back a fresh accumulator" do
      assert State.new() == Reconciliation.new_state()
    end
  end
end
