defmodule Core.Repo.Migrations.AddStorageBuiltIn do
  use Ecto.Migration

  def up do
    create table(:storage_endpoints_builtin) do
      add(:key, :string, null: false)
      timestamps()
    end

    create(unique_index(:storage_endpoints_builtin, [:key]))

    alter table(:storage_endpoints) do
      add(:builtin_id, references(:storage_endpoints_builtin, on_delete: :nilify_all), null: true)
    end

    drop(constraint(:storage_endpoints, :must_have_at_most_one_special))

    create(
      constraint(:storage_endpoints, :must_have_at_most_one_special,
        check: """
        2 > CASE WHEN aws_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN azure_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN centerdata_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN yoda_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN builtin_id IS NULL THEN 0 ELSE 1 END
        """
      )
    )
  end

  def down do
    drop(constraint(:storage_endpoints, :must_have_at_most_one_special))

    alter table(:storage_endpoints) do
      remove(:builtin_id)
    end

    create(
      constraint(:storage_endpoints, :must_have_at_most_one_special,
        check: """
        2 > CASE WHEN aws_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN azure_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN centerdata_id IS NULL THEN 0 ELSE 1 END +
        CASE WHEN yoda_id IS NULL THEN 0 ELSE 1 END
        """
      )
    )

    drop(index(:storage_endpoints_builtin, [:key]))
    drop(table(:storage_endpoints_builtin))
  end
end
