defmodule Systems.Bookkeeping.Factories do
  alias Core.Factories

  alias Systems.{
    Bookkeeping
  }

  def create_entry(from, to, amount, idempotence_key, journal_message) do
    entry =
      Factories.insert!(:book_entry, %{
        idempotence_key: idempotence_key,
        journal_message: journal_message
      })

    Factories.insert!(:book_line, %{account: from, entry: entry, debit: amount, credit: 0})
    Factories.insert!(:book_line, %{account: to, entry: entry, debit: 0, credit: amount})

    Bookkeeping.Context.get_entry(idempotence_key, lines: [:account])
  end
end
