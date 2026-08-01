defmodule Core.Repo.Migrations.RenameAssignmentInstanceToParticipation do
  use Ecto.Migration

  def up do
    rename(table(:assignment_instance), to: table(:assignment_participation))

    execute("ALTER INDEX assignment_instance_pkey RENAME TO assignment_participation_pkey")

    execute(
      "ALTER INDEX assignment_instance_user_id_index RENAME TO assignment_participation_user_id_index"
    )

    execute(
      "ALTER INDEX assignment_instance_assignment_id_index RENAME TO assignment_participation_assignment_id_index"
    )

    execute("ALTER INDEX assignment_instance_unique RENAME TO assignment_participation_unique")

    execute(
      "ALTER TABLE assignment_participation RENAME CONSTRAINT assignment_instance_user_id_fkey TO assignment_participation_user_id_fkey"
    )

    execute(
      "ALTER TABLE assignment_participation RENAME CONSTRAINT assignment_instance_assignment_id_fkey TO assignment_participation_assignment_id_fkey"
    )
  end

  def down do
    execute(
      "ALTER TABLE assignment_participation RENAME CONSTRAINT assignment_participation_assignment_id_fkey TO assignment_instance_assignment_id_fkey"
    )

    execute(
      "ALTER TABLE assignment_participation RENAME CONSTRAINT assignment_participation_user_id_fkey TO assignment_instance_user_id_fkey"
    )

    execute("ALTER INDEX assignment_participation_unique RENAME TO assignment_instance_unique")

    execute(
      "ALTER INDEX assignment_participation_assignment_id_index RENAME TO assignment_instance_assignment_id_index"
    )

    execute(
      "ALTER INDEX assignment_participation_user_id_index RENAME TO assignment_instance_user_id_index"
    )

    execute("ALTER INDEX assignment_participation_pkey RENAME TO assignment_instance_pkey")

    rename(table(:assignment_participation), to: table(:assignment_instance))
  end
end
