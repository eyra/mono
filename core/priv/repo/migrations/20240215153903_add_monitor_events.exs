defmodule Core.Repo.Migrations.AddMonitorEvents do
  use Ecto.Migration

  def up do
    update_all(:crew_members, {:declined, true}, {:expired, true})
    update_all(:crew_tasks, {:status, "'declined'"}, {:expired, true})
    update_all(:crew_tasks, {:status, "'declined'"}, {:status, "'pending'"})

    create table(:monitor_events) do
      add(:identifier, {:array, :string}, null: false)
      add(:value, :integer, null: false)
      timestamps()
    end

    alter table(:crew_tasks) do
      remove(:declined_at)
    end

    alter table(:crew_members) do
      remove(:declined)
      remove(:declined_at)
    end
  end

  def down do
    alter table(:crew_members) do
      add(:declined_at, :naive_datetime)
      add(:declined, :boolean)
    end

    alter table(:crew_tasks) do
      add(:declined_at, :naive_datetime)
    end

    drop(table(:monitor_events))
  end

  ########## HELPERS ##########

  defp update_all(table, {field1, value1}, {field2, value2}) do
    execute("""
    UPDATE #{table} SET #{field2} = #{value2} WHERE #{field1} = #{value1};
    """)
  end
end
