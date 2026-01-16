defmodule Core.Repo.Migrations.AddConsent do
  use Ecto.Migration

  def up do
    create table(:consent_agreements) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:consent_revisions) do
      add(:agreement_id, references(:consent_agreements, on_delete: :nothing))
      add(:source, :text)
      timestamps()
    end

    create table(:consent_signatures) do
      add(:revision_id, references(:consent_revisions, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))
      timestamps()
    end

    create(unique_index(:consent_signatures, [:revision_id, :user_id]))

    alter table(:assignments) do
      add(:consent_agreement_id, references(:consent_agreements), null: true)
    end
  end

  def down do
    alter table(:assignments) do
      remove(:consent_agreement_id)
    end

    drop(index(:consent_signatures, [:revision_id, :user_id]))

    drop(table(:consent_signatures))
    drop(table(:consent_revisions))
    drop(table(:consent_agreements))
  end
end
