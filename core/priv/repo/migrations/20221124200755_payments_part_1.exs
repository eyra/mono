defmodule Core.Repo.Migrations.PaymentsPart1 do
  use Ecto.Migration

  def up do
    alter table(:budgets) do
      add(:icon, {:array, :string}, null: true)
    end

    alter table(:pools) do
      add(:icon, {:array, :string}, null: true)
      add(:director, :string, null: true)
      add(:archived, :boolean, default: false)
      add(:auth_node_id, references(:authorization_nodes), null: true)
    end

    alter table(:org_nodes) do
      add(:domains, {:array, :string}, null: true)
    end

    alter table(:currencies) do
      add(:type, :string, default: "virtual")
    end

    create(unique_index(:currencies, [:name]))

    create table(:bank_accounts) do
      add(:name, :string, null: false)
      add(:icon, {:array, :string}, null: true)
      add(:currency_id, references(:currencies), null: false)
      add(:account_id, references(:book_accounts), null: false)
      timestamps()
    end
  end

  def down do
    drop(table(:bank_accounts))

    drop(index(:currencies, [:name]))

    alter table(:currencies) do
      remove(:type)
    end

    alter table(:org_nodes) do
      remove(:domains)
    end

    alter table(:pools) do
      remove(:icon)
      remove(:director)
      remove(:archived)
      remove(:auth_node_id)
    end

    alter table(:budgets) do
      remove(:icon)
    end
  end
end
