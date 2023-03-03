defmodule Systems.Bookkeeping.AccountModel do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          identifier: list(binary()),
          balance_debit: integer(),
          balance_credit: integer()
        }

  schema "book_accounts" do
    field(:identifier, {:array, :string})
    field(:balance_debit, :integer)
    field(:balance_credit, :integer)
    timestamps()
  end

  @fields ~w(identifier balance_debit balance_credit)a
  @required_fields @fields

  def checksum(term) do
    to_identifier(term)
    |> Enum.join()
    |> :erlang.crc32()
    |> Integer.to_string(32)
  end

  def create(term) do
    %__MODULE__{
      identifier: to_identifier(term),
      balance_debit: 0,
      balance_credit: 0
    }
  end

  def change(account, %{} = attrs) do
    account
    |> cast(attrs, @fields)
  end

  def validate(changeset, condition \\ true) do
    if condition do
      changeset
      |> validate_required(@required_fields)
      |> unique_constraint(:identifier)
    else
      changeset
    end
  end

  def changeset(account, %{} = attrs) do
    account
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:identifier)
  end

  def valid_checksum?(account, checksum) do
    checksum(account) == checksum
  end

  def balance(%{balance_debit: debit, balance_credit: credit}), do: credit - debit

  def to_identifier(%__MODULE__{identifier: identifier}), do: identifier

  def to_identifier({type, subtype, id}) when is_binary(subtype) and is_integer(id) do
    to_identifier([type, subtype, id])
  end

  def to_identifier({type, subtype}) when is_binary(subtype) do
    to_identifier([type, subtype])
  end

  def to_identifier({type, id}) when is_integer(id) do
    to_identifier([type, id])
  end

  def to_identifier(type) when is_atom(type) do
    to_identifier([type])
  end

  def to_identifier(term) when is_list(term), do: Enum.map(term, &to_string(&1))
end
