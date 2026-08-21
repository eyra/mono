defmodule Core.Repo.Migrations.DeprecateNotificationTables do
  use Ecto.Migration

  # Systems.Notification has been retired in favour of Systems.Notify.
  # Following the deferred-drop pattern (see docs/schema-deprecations.md):
  # this migration only stamps a COMMENT on each table for DB-side
  # discoverability; the actual DROP is scheduled for a follow-up
  # migration once we're confident no reader remains.
  def up do
    execute(
      ~s|COMMENT ON TABLE notifications IS 'DEPRECATED 2026-08-14 — Systems.Notification retired; table drop pending'|
    )

    execute(
      ~s|COMMENT ON TABLE notification_boxes IS 'DEPRECATED 2026-08-14 — Systems.Notification retired; table drop pending'|
    )

    execute(
      ~s|COMMENT ON TABLE notification_center_logs IS 'DEPRECATED 2026-08-14 — Systems.Notification retired; table drop pending'|
    )
  end

  def down do
    execute("COMMENT ON TABLE notifications IS NULL")
    execute("COMMENT ON TABLE notification_boxes IS NULL")
    execute("COMMENT ON TABLE notification_center_logs IS NULL")
  end
end
