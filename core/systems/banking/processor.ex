defmodule Systems.Banking.Processor do
  defstruct [:strategy, :currency]

  alias Systems.{
    Bookkeeping
  }

  @account_type :bank

  # amount received -> create booking & update fund
  def next(
        %__MODULE__{strategy: strategy, currency: currency},
        %{id: id, amount: amount, date: date, description: description, type: type} = payment
      ) do
    bank_account = strategy.resolve(currency, @account_type)
    account = strategy.resolve(currency, description)

    lines = lines(bank_account, account, amount, type)

    %{
      idempotence_key: to_string(id),
      journal_message:
        "Bank transaction: #{id} at: #{date} for: #{amount} from: #{payment.from_iban} to: #{payment.to_iban}",
      lines: lines
    }
    |> Bookkeeping.Public.enter()
  end

  defp lines(bank_account, account, amount, :received) do
    [
      %{account: bank_account, debit: amount},
      %{account: account, credit: amount}
    ]
  end

  defp lines(bank_account, account, amount, :payed) do
    [
      %{account: account, debit: amount},
      %{account: bank_account, credit: amount}
    ]
  end
end
