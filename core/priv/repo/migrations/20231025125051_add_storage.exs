defmodule Core.Repo.Migrations.AddStorage do
  use Ecto.Migration

  def up do
    create table(:storage_endpoints_aws) do
      add(:access_key_id, :string)
      add(:secret_access_key, :string)
      add(:s3_bucket_name, :string)
      add(:region_code, :string)

      timestamps()
    end

    create table(:storage_endpoints_azure) do
      add(:account_name, :string)
      add(:container, :string)
      add(:sas_token, :string)

      timestamps()
    end

    create table(:storage_endpoints_centerdata) do
      add(:url, :string)

      timestamps()
    end

    create table(:storage_endpoints_yoda) do
      add(:url, :string)
      add(:user, :string)
      add(:password, :string)

      timestamps()
    end

    create table(:storage_endpoints) do
      add(:aws_id, references(:storage_endpoints_aws, on_delete: :nilify_all), null: true)
      add(:azure_id, references(:storage_endpoints_azure, on_delete: :nilify_all), null: true)

      add(:centerdata_id, references(:storage_endpoints_centerdata, on_delete: :nilify_all),
        null: true
      )

      add(:yoda_id, references(:storage_endpoints_yoda, on_delete: :nilify_all), null: true)
      timestamps()
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

    alter table(:assignments) do
      add(:storage_endpoint_id, references(:storage_endpoints, on_delete: :nilify_all),
        null: true
      )

      add(:external_panel, :string, null: true)
    end
  end

  def down do
    alter table(:assignments) do
      remove(:storage_endpoint_id)
      remove(:external_panel)
    end

    drop(constraint(:storage_endpoints, :must_have_at_most_one_special))

    drop(table(:storage_endpoints))
    drop(table(:storage_endpoints_yoda))
    drop(table(:storage_endpoints_centerdata))
    drop(table(:storage_endpoints_azure))
    drop(table(:storage_endpoints_aws))
  end
end
