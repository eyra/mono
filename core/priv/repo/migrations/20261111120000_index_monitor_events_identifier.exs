defmodule Mica.Repo.Migrations.IndexMonitorEventsIdentifier do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  # Expression index: Systems.Monitor.Queries matches with
  # `identifier::text[] @> $1`, and only an index on the same expression serves it.
  def up do
    create_if_not_exists(
      index(:monitor_events, ["(identifier::text[])"],
        name: :monitor_events_identifier_text_index,
        using: :gin,
        concurrently: true
      )
    )
  end

  def down do
    drop_if_exists(
      index(:monitor_events, ["(identifier::text[])"],
        name: :monitor_events_identifier_text_index,
        concurrently: true
      )
    )
  end
end
