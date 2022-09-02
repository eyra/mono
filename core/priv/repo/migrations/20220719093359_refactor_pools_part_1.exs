defmodule Core.Repo.Migrations.RefactorPoolsPart1 do
  use Ecto.Migration

  def up do
    create table(:text_bundles) do
      timestamps()
    end

    create table(:text_items) do
      add(:locale, :string, null: true)
      add(:text, :string, null: true)
      add(:text_plural, :string, null: true)
      add(:bundle_id, references(:text_bundles), null: false)
      timestamps()
    end

    create table(:currencies) do
      add(:name, :string, null: true)
      add(:decimal_scale, :integer, null: true)
      add(:label_bundle_id, references(:text_bundles), null: true)
      timestamps()
    end

    create table(:budgets) do
      add(:name, :string, null: false)
      add(:currency_id, references(:currencies), null: false)
      add(:fund_id, references(:book_accounts), null: false)
      add(:reserve_id, references(:book_accounts), null: true)
      add(:auth_node_id, references(:authorization_nodes), null: false)

      timestamps()
    end

    create table(:org_nodes) do
      add(:type, :string, null: false)
      add(:identifier, {:array, :string}, null: false)
      add(:short_name_bundle_id, references(:text_bundles), null: true)
      add(:full_name_bundle_id, references(:text_bundles), null: true)

      timestamps()
    end

    create(index(:org_nodes, :identifier, unique: true))

    create table(:org_users) do
      add(:org_id, references(:org_nodes), null: false)
      add(:user_id, references(:users), null: false)
      timestamps()
    end

    create(unique_index(:org_users, [:org_id, :user_id]))

    create table(:org_links) do
      add(:from_id, references(:org_nodes), null: false)
      add(:to_id, references(:org_nodes), null: false)
      timestamps()
    end

    create index(:org_links, [:from_id])
    create index(:org_links, [:to_id])

    create unique_index(
      :org_links,
      [:from_id, :to_id],
      name: :org_links_from_id_to_id_index
    )

    create unique_index(
      :org_links,
      [:to_id, :from_id],
      name: :org_links_to_id_from_id_index
    )

    create table(:budget_rewards) do
      add(:idempotence_key, :string, null: false)
      add(:amount, :integer, null: false)
      add(:attempt, :integer, default: 0)
      add(:budget_id, references(:budgets), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:deposit_id, references(:book_entries), null: true)
      add(:payment_id, references(:book_entries), null: true)

      timestamps()
    end

    create(index(:budget_rewards, :idempotence_key, unique: true))

    alter table(:assignments) do
      add(:budget_id, references(:budgets, on_delete: :delete_all), null: true)
    end

    alter table(:pools) do
      add(:org_id, references(:org_nodes), null: true)
      add(:currency_id, references(:currencies, on_delete: :delete_all), null: true)
      add(:target, :integer, null: true)
    end

    create table(:campaign_submissions) do
      add(:campaign_id, references(:campaigns, on_delete: :delete_all), null: false)
      add(:submission_id, references(:pool_submissions, on_delete: :delete_all), null: false)
      timestamps()
    end

    create(unique_index(:campaign_submissions, [:submission_id]))

    drop(index(:pool_submissions, [:pool_id, :promotion_id]))

    drop(constraint(:pool_submissions, "pool_submissions_promotion_id_fkey"))
    alter table(:pool_submissions) do
      modify(:promotion_id, references(:promotions, on_delete: :delete_all), null: true)
    end
  end

  def down do
    create(unique_index(:pool_submissions, [:pool_id, :promotion_id]))

    drop(index(:campaign_submissions, [:submission_id]))
    drop table(:campaign_submissions)

    alter table(:pools) do
      remove(:org_id)
      remove(:currency_id)
      remove(:target)
    end

    alter table(:assignments) do
      remove(:budget_id)
    end

    drop table(:budget_rewards)
    drop table(:budgets)
    drop table(:org_users)
    drop table(:org_links)
    drop table(:org_nodes)

    drop table(:currencies)
    drop table(:text_items)
    drop table(:text_bundles)
  end
end
