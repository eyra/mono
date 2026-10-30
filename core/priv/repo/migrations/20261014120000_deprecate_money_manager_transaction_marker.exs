defmodule Mica.Repo.Migrations.DeprecateMoneyManagerTransactionMarker do
  use Ecto.Migration

  # Systems.Banking has been retired. Following the deferred-drop pattern
  # (see docs/schema-deprecations.md): this migration only stamps a COMMENT
  # on the table for DB-side discoverability; the actual DROP is scheduled
  # for a follow-up migration.
  def up do
    execute(
      ~s|COMMENT ON TABLE money_manager_transaction_marker IS 'DEPRECATED 2026-10-14 — Systems.Banking retired; table drop pending'|
    )
  end

  def down do
    execute("COMMENT ON TABLE money_manager_transaction_marker IS NULL")
  end
end
