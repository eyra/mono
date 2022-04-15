defmodule Systems.Bookkeeping.AccountModel do
  use Ecto.Schema

  schema "book_accounts" do
    field(:identifier, {:array, :string})
    field(:balance_debit, :integer)
    field(:balance_credit, :integer)
    timestamps()
  end
end