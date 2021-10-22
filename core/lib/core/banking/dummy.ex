defmodule Core.Banking.Dummy do
  use GenServer
  @behaviour Core.Banking.Backend
  @payment_batch_size 8

  def start_link(account) do
    GenServer.start_link(__MODULE__, account, name: __MODULE__)
  end

  def init(account) do
    {:ok, %{account: account, payments: []}}
  end

  def handle_call(:get_payments, _, %{payments: payments} = state) do
    {:reply, payments, state}
  end

  def handle_call({:submit_payment, payment}, _, %{payments: payments} = state) do
    case check_for_existing_idempotency_key(payments, payment.idempotence_key) do
      :ok ->
        payments = add_payment(payments, payment)
        state = Map.put(state, :payments, payments)
        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def list_payments(since) do
    payment_offset =
      case since do
        nil -> 0
        _ -> String.to_integer(since)
      end

    payments = GenServer.call(__MODULE__, :get_payments)

    batch = payments |> Enum.slice(payment_offset, @payment_batch_size)

    %{
      has_more: Enum.count(payments) > payment_offset + @payment_batch_size,
      payments: batch,
      marker: payments |> Enum.count() |> to_string()
    }
  end

  def submit_payment(payment) do
    GenServer.call(__MODULE__, {:submit_payment, payment})
  end

  defp add_payment(payments, payment) do
    [Map.put(payment, :date, DateTime.utc_now()) | payments]
  end

  defp check_for_existing_idempotency_key(payments, key) do
    if Enum.any?(payments, &(&1.idempotence_key == key)) do
      {:error, "The payment with the given ID already exists"}
    else
      :ok
    end
  end
end
