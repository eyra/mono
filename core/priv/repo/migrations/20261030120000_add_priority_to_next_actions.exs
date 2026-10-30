defmodule Core.Repo.Migrations.AddPriorityToNextActions do
  use Ecto.Migration

  def change do
    alter table(:next_actions) do
      add(:priority, :integer, null: false, default: 0)
    end
  end
end
