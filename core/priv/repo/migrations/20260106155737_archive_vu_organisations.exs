defmodule Core.Repo.Migrations.ArchiveVuOrganisations do
  use Ecto.Migration

  def up do
    # Archive all organisations with "vu" in their identifier
    execute("""
    UPDATE org_nodes
    SET archived_at = NOW()
    WHERE 'vu' = ANY(identifier)
    AND archived_at IS NULL
    """)
  end

  def down do
    # Unarchive all VU organisations
    execute("""
    UPDATE org_nodes
    SET archived_at = NULL
    WHERE 'vu' = ANY(identifier)
    """)
  end
end
