defmodule Core.Repo.Migrations.AddInstructionTool do
  use Ecto.Migration

  def up do
    create table(:content_repositories) do
      add(:platform, :string)
      add(:url, :string)
      timestamps()
    end

    create table(:instruction_tools) do
      add(:auth_node_id, references(:authorization_nodes), null: false)
      timestamps()
    end

    create table(:instruction_assets) do
      add(:tool_id, references(:instruction_tools, on_delete: :delete_all), null: false)
      add(:repository_id, references(:content_repositories, on_delete: :delete_all), null: true)
      add(:file_id, references(:content_files, on_delete: :delete_all), null: true)
      timestamps()
    end

    create(
      constraint(:instruction_assets, :must_have_at_least_one_ref,
        check: """
        repository_id != null or
        file_id != null
        """
      )
    )

    create table(:instruction_pages) do
      add(:tool_id, references(:instruction_tools, on_delete: :delete_all), null: false)
      add(:page_id, references(:content_pages, on_delete: :delete_all), null: false)
      timestamps()
    end

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      add(:instruction_tool_id, references(:instruction_tools, on_delete: :delete_all),
        null: true
      )
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        alliance_tool_id != null or
        feldspar_tool_id != null or
        document_tool_id != null or
        lab_tool_id != null or
        graphite_tool_id != null or
        instruction_tool_id != null
        """
      )
    )
  end

  def down do
    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      remove(:instruction_tool_id)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        alliance_tool_id != null or
        feldspar_tool_id != null or
        document_tool_id != null or
        lab_tool_id != null or
        graphite_tool_id != null
        """
      )
    )

    drop(constraint(:instruction_assets, :must_have_at_least_one_ref))

    drop(table(:instruction_pages))
    drop(table(:instruction_assets))
    drop(table(:instruction_tools))
    drop(table(:content_repositories))
  end
end
