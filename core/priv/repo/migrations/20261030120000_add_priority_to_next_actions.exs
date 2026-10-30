defmodule Core.Repo.Migrations.AddPriorityToNextActions do
  use Ecto.Migration

  def change do
    alter table(:next_actions) do
      add(:priority, :integer, null: false, default: 0)
    end

    create(
      constraint(:next_actions, :next_actions_priority_check, check: "priority IN (-10, 0, 10)")
    )
  end
end
