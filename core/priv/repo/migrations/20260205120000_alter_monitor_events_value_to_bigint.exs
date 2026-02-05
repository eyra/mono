defmodule Core.Repo.Migrations.AlterMonitorEventsValueToBigint do
  use Ecto.Migration

  def change do
    alter table(:monitor_events) do
      modify(:value, :bigint, from: :integer)
    end
  end
end
