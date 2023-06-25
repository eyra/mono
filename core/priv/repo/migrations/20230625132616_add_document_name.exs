defmodule Core.Repo.Migrations.AddDocumentName do
  use Ecto.Migration

  def up do
    alter table(:data_donation_document_tasks) do
      add(:document_name, :string, null: true)
    end
  end

  def down do
    alter table(:data_donation_document_tasks) do
      remove(:document_name)
    end
  end
end
