defmodule Mica.Repo.Migrations.GiveCreatorsATransitionPublishLicense do
  use Ecto.Migration

  # Every creator who can publish before licenses (`creator` and `verified_at`
  # set, the old publish check) gets a Publish license until 90 days after this
  # migration runs, so support has time to give them the license. Nobody gets
  # Pay-in. Given by no one: `granted_by_id` stays empty.
  #
  # `verified_at` is read here in SQL; the schema field is gone, the column is
  # dropped in a later migration, which must run after this one.
  def up do
    execute("""
    INSERT INTO licenses (user_id, license, valid_until, granted_at, inserted_at, updated_at)
    SELECT id, 'publish', (now() AT TIME ZONE 'UTC')::date + 90,
      date_trunc('second', now() AT TIME ZONE 'UTC'),
      date_trunc('second', now() AT TIME ZONE 'UTC'),
      date_trunc('second', now() AT TIME ZONE 'UTC')
    FROM users
    WHERE creator = true AND verified_at IS NOT NULL
    """)

    execute(
      ~s|COMMENT ON COLUMN users.verified_at IS 'DEPRECATED 2026-11-26 — schema field removed, licenses replace it; column drop pending'|
    )
  end

  # Removes the transition licenses: given by no one, with the transition's end
  # date. A license support gave in the meantime stays.
  def down do
    execute("COMMENT ON COLUMN users.verified_at IS NULL")

    execute("""
    DELETE FROM licenses
    WHERE license = 'publish' AND granted_by_id IS NULL
      AND valid_until = granted_at::date + 90
    """)
  end
end
