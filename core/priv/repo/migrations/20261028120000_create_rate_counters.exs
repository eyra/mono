defmodule Core.Repo.Migrations.CreateRateCounters do
  use Ecto.Migration

  def change do
    create table(:rate_counters, primary_key: false) do
      add(:key, :binary, primary_key: true)
      add(:window_start, :utc_datetime, primary_key: true)
      add(:expires_at, :utc_datetime, null: false)
      add(:count, :integer, null: false, default: 0)
    end

    create(index(:rate_counters, [:expires_at]))
  end
end
