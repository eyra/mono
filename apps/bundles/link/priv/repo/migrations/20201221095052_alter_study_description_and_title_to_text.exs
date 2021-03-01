defmodule Link.Repo.Migrations.AlterStudyDescriptionAndTitleToText do
  use Ecto.Migration

  def change do
    alter table(:studies) do
      modify(:title, :text)
      modify(:description, :text)
    end
  end
end
