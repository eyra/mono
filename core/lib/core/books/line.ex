defmodule Core.Books.Line do
  use Ecto.Schema

  schema "book_entry_lines" do
    belongs_to(:entry, Core.Books.Entry)
    belongs_to(:book, Core.Books.Book)
    field(:debit, :integer)
    field(:credit, :integer)
  end
end
