defmodule Systems.Bookkeeping.EntryModel do
  use Ecto.Schema

  schema "book_entries" do
    field(:idempotence_key, :string)
    field(:journal_message, :string)
    timestamps()
  end
end
