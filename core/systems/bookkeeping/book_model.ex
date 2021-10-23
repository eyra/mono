defmodule Systems.Bookkeeping.BookModel do
  use Ecto.Schema

  schema "books" do
    field(:identifier, {:array, :string})
    field(:balance_debit, :integer)
    field(:balance_credit, :integer)
    timestamps()
  end
end
