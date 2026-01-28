defmodule Core.Repo.Migrations.BackfillAuthNodesForOrgNodes do
  use Ecto.Migration

  def up do
    # For each org_node without an auth_node, create one and link it
    execute("""
    WITH new_auth_nodes AS (
      INSERT INTO authorization_nodes (inserted_at, updated_at)
      SELECT NOW(), NOW()
      FROM org_nodes
      WHERE auth_node_id IS NULL
      RETURNING id
    ),
    numbered_nodes AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY id) as rn
      FROM org_nodes
      WHERE auth_node_id IS NULL
    ),
    numbered_auth AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY id) as rn
      FROM new_auth_nodes
    )
    UPDATE org_nodes
    SET auth_node_id = numbered_auth.id
    FROM numbered_nodes, numbered_auth
    WHERE org_nodes.id = numbered_nodes.id
    AND numbered_nodes.rn = numbered_auth.rn
    """)
  end

  def down do
    # Remove auth_node references (but keep the auth_nodes for safety)
    execute("UPDATE org_nodes SET auth_node_id = NULL")
  end
end
