defmodule Core.Repo.Migrations.AddStudentId do
  use Ecto.Migration

  def up do
    alter table(:surfconext_users) do
      add(:schac_personal_unique_code, {:array, :string})
    end
  end

  def down do
    alter table(:surfconext_users) do
      remove(:schac_personal_unique_code)
    end
  end
end
