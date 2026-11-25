defmodule Mica.Repo.Migrations.AddResearchInstitutesToOrgs do
  use Ecto.Migration

  # The :member role on the organisation's auth node stays the membership itself.
  # A row in org_memberships records who added the member and, once removed, who
  # removed them and when. Members added before this migration have no row.
  def change do
    alter table(:org_nodes) do
      add(:research_institute_at, :utc_datetime)
      add(:research_institute_by_id, references(:users, on_delete: :nilify_all))
    end

    create table(:org_memberships) do
      add(:org_id, references(:org_nodes, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:added_by_id, references(:users, on_delete: :nilify_all))
      add(:removed_at, :utc_datetime)
      add(:removed_by_id, references(:users, on_delete: :nilify_all))

      timestamps()
    end

    create(
      index(:org_memberships, [:org_id, :user_id],
        unique: true,
        where: "removed_at IS NULL",
        name: :org_memberships_current_index
      )
    )

    create(index(:org_memberships, [:user_id]))
  end
end
