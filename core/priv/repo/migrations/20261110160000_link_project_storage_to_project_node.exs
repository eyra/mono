defmodule Mica.Repo.Migrations.LinkProjectStorageToProjectNode do
  @moduledoc """
  A project's storage item ("Data") was created after the project's authorization
  tree was linked, so its storage endpoint had no parent until another item was
  added to the project. Its owners could not open the storage endpoint page.
  Links every storage endpoint of a project item that has no parent yet to the
  item's project node.
  """
  use Ecto.Migration

  def up do
    execute("""
    UPDATE authorization_nodes AS endpoint_auth
    SET parent_id = node.auth_node_id
    FROM project_items AS item
    JOIN project_nodes AS node ON node.id = item.node_id
    JOIN storage_endpoints AS endpoint ON endpoint.id = item.storage_endpoint_id
    WHERE endpoint_auth.id = endpoint.auth_node_id
      AND endpoint_auth.parent_id IS NULL
    """)
  end

  def down, do: :ok
end
