defmodule Core.Repo.Migrations.BooksTables do
  use Ecto.Migration

  def change do
    create table(:books) do
      add(:identifier, {:array, :string}, null: false)
      add(:balance_debit, :integer, null: false)
      add(:balance_credit, :integer, null: false)
      timestamps()
    end

    create(index(:books, :identifier, unique: true))

    create(constraint(:books, :book_balance_debit_must_be_positive, check: "balance_debit >= 0"))

    create(
      constraint(:books, :book_balance_credit_must_be_positive, check: "balance_credit >= 0")
    )

    create table(:book_entries) do
      add(:idempotence_key, :string, null: false)
      add(:journal_message, :text, null: false)
      timestamps()
    end

    create(index(:book_entries, :idempotence_key, unique: true))

    create table(:book_entry_lines) do
      add(:book_id, references(:books), null: false)
      add(:entry_id, references(:book_entries), null: false)
      add(:debit, :integer)
      add(:credit, :integer)
    end

    create(
      constraint(:book_entry_lines, :book_entry_must_have_either_credit_or_debit,
        check: "(debit > 0 and credit = 0) or (credit > 0 and debit = 0)"
      )
    )
  end
end
