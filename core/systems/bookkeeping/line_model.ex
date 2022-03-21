defmodule Systems.Bookkeeping.LineModel do
  use Ecto.Schema

  schema "book_entry_lines" do
    belongs_to(:entry, Systems.Bookkeeping.EntryModel)
    belongs_to(:account, Systems.Bookkeeping.AccountModel)
    field(:debit, :integer)
    field(:credit, :integer)
  end
end
