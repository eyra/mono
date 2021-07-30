defmodule Core.Repo.Migrations.AddStudentRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:student, :boolean)
    end
  end
end
