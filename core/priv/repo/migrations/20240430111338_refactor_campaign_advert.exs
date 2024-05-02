defmodule Core.Repo.Migrations.RefactorCampaignAdvertisement do
  use Ecto.Migration

  def up do
    drop(table(:authors))
    drop(table(:campaign_submissions))

    rename(table(:campaigns), to: table(:adverts))
    rename(table(:adverts), :promotable_assignment_id, to: :assignment_id)

    alter table(:adverts) do
      add(:submission_id, references(:pool_submissions), null: false)
    end

    alter table(:assignments) do
      remove(:director)
    end

    create table(:pool_branding) do
      add(:title, :string, null: true)
      add(:description, :string, null: true)
      add(:logo_url, :string)
      add(:pool_id, references(:pools))
    end

    create(unique_index(:pool_branding, [:pool_id]))
  end

  def down do
    drop(index(:pool_branding, [:pool_id]))
    drop(table(:pool_branding))

    alter table(:assignments) do
      add(:director, :string)
    end

    alter table(:adverts) do
      remove(:submission_id)
    end

    rename(table(:adverts), :assignment_id, to: :promotable_assignment_id)
    rename(table(:adverts), to: table(:campaigns))

    create table(:campaign_submissions) do
      add(:campaign_id, references(:campaigns, on_delete: :delete_all), null: false)
      add(:submission_id, references(:pool_submissions, on_delete: :delete_all), null: false)
      timestamps()
    end

    create table(:authors) do
      add(:fullname, :string)
      add(:displayname, :string)

      add(:campaign_id, references(:campaigns, on_delete: :delete_all), null: true)
      add(:user_id, references(:users, on_delete: :nothing), null: true)

      timestamps()
    end
  end
end
