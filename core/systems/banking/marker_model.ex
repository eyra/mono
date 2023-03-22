defmodule Systems.Banking.MarkerModel do
  use Ecto.Schema

  schema "money_manager_transaction_marker" do
    field(:marker, :string)
    field(:payment_count, :integer)
    timestamps()
  end
end
