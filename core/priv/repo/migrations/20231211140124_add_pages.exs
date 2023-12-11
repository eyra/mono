defmodule Core.Repo.Migrations.AddPages do
  use Ecto.Migration

  def up do
    create table(:content_pages) do
      add(:body, :text)
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:assignment_page_refs, primary_key: false) do
      add(:key, :string)

      add(:assignment_id, references(:assignments, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(:page_id, references(:content_pages, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      timestamps()
    end
  end

  def down do
    drop(table(:assignment_page_refs))
    drop(table(:content_pages))
  end
end
