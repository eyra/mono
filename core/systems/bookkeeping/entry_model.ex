defmodule Systems.Bookkeeping.EntryModel do
  use Ecto.Schema

  schema "book_entries" do
    field(:idempotence_key, :string)
    field(:journal_message, :string)

    has_many(:lines, Systems.Bookkeeping.LineModel, foreign_key: :entry_id)

    timestamps()
  end
end
