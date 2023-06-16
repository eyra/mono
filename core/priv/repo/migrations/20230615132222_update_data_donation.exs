defmodule Core.Repo.Migrations.UpdateDataDonation do
  use Ecto.Migration

  def up do
    alter table(:data_donation_tools) do
      add(:status, :string, null: true)
    end

    create table(:data_donation_document_tasks) do
      add(:document_ref, :string, null: true)
      timestamps()
    end

    create table(:data_donation_survey_tasks) do
      timestamps()
    end

    create table(:data_donation_donate_tasks) do
      timestamps()
    end

    drop(table(:data_donation_tasks))

    create table(:data_donation_tasks) do
      add(:position, :integer, null: false)
      add(:title, :string, null: true)
      add(:description, :string, null: true)
      add(:platform, :string, null: true)
      add(:tool_id, references(:data_donation_tools, on_delete: :delete_all), null: true)

      add(:survey_task_id, references(:data_donation_survey_tasks, on_delete: :delete_all),
        null: true
      )

      add(:request_task_id, references(:data_donation_document_tasks, on_delete: :delete_all),
        null: true
      )

      add(:download_task_id, references(:data_donation_document_tasks, on_delete: :delete_all),
        null: true
      )

      add(:donate_task_id, references(:data_donation_donate_tasks, on_delete: :delete_all),
        null: true
      )

      timestamps()
    end

    create(
      constraint(:data_donation_tasks, :must_have_at_least_one_special,
        check: """
        survey_task_id != null or
        request_task_id != null or
        download_task_id != null or
        donate_task_id != null
        """
      )
    )

    create table(:data_donation_spots) do
      add(:tool_id, references(:data_donation_tools), null: false)
      add(:auth_node_id, references(:authorization_nodes), null: false)

      timestamps()
    end

    create table(:data_donation_task_spot_status, primary_key: false) do
      add(:status, :string, null: false)
      add(:spot_id, references(:data_donation_spots, on_delete: :delete_all), primary_key: true)
      add(:task_id, references(:data_donation_tasks, on_delete: :delete_all), primary_key: true)
      timestamps()
    end
  end

  def down do
    drop(table(:data_donation_task_spot_status))
    drop(table(:data_donation_spots))

    drop(constraint(:data_donation_tasks, :must_have_at_least_one_special))
    drop(table(:data_donation_tasks))
    create(table(:data_donation_tasks))

    drop(table(:data_donation_survey_tasks))
    drop(table(:data_donation_document_tasks))
    drop(table(:data_donation_donate_tasks))

    alter table(:data_donation_tools) do
      remove(:status, :string)
    end
  end
end
