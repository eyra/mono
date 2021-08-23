defmodule Core.Repo.Migrations.UpdatePoolCriteria do
  use Ecto.Migration

  def change do

    alter table(:promotions) do
      remove(:published_at)
    end

    create table(:pools) do
      add(:name, :string, null: false)
      timestamps()
    end

    create table(:pool_participants, primary_key: false) do
      add(:pool_id, references(:pools, on_delete: :delete_all), null: false, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true)
      timestamps()
    end

    create table(:pool_submissions) do
      add(:status, :string, null: false)
      add(:pool_id, references(:pools, on_delete: :delete_all), null: false)
      add(:promotion_id, references(:promotions, on_delete: :delete_all), null: false)
      add(:content_node_id, references(:content_nodes), null: false)
      timestamps()
    end

    create(unique_index(:pool_submissions, [:pool_id, :promotion_id]))

    drop(index(:eligibility_criteria, [:study_id]))

    alter table(:eligibility_criteria) do
      remove(:study_id)
      add(:submission_id, references(:pool_submissions, on_delete: :delete_all))
    end

    create(unique_index(:eligibility_criteria, [:submission_id]))

  end
end
