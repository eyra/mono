defmodule Core.Repo.Migrations.AddOnyx do
  use Ecto.Migration

  def up do
    create table(:onyx_tool) do
      add(:director, :string)
      add(:auth_node_id, references(:authorization_nodes, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_paper) do
      add(:year, :string)
      add(:date, :string)
      add(:abbreviated_journal, :string)
      add(:doi, :string)
      add(:title, :text)
      add(:subtitle, :text)
      add(:abstract, :text)
      add(:authors, {:array, :string})
      add(:keywords, {:array, :string})
      timestamps()
    end

    create table(:onyx_tool_file) do
      add(:status, :string, null: false)
      add(:tool_id, references(:onyx_tool, on_delete: :delete_all))
      add(:file_id, references(:content_files, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_file_paper) do
      add(:tool_file_id, references(:onyx_tool_file, on_delete: :delete_all))
      add(:paper_id, references(:onyx_paper, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_file_error) do
      add(:tool_file_id, references(:onyx_tool_file, on_delete: :delete_all))
      add(:error, :string)
      timestamps()
    end

    create table(:onyx_ris) do
      add(:raw, :text)
      add(:paper_id, references(:onyx_paper, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_criterion_group) do
      add(:class, :string)
      add(:tool_id, references(:onyx_tool, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_criterion) do
      add(:value, :string)
      add(:group_id, references(:onyx_criterion_group, on_delete: :delete_all))
      timestamps()
    end

    create table(:onyx_label) do
      add(:name, :string)
      add(:color, :string)
      add(:criterion_id, references(:onyx_criterion, on_delete: :delete_all))
      timestamps()
    end

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      add(:onyx_tool_id, references(:onyx_tool, on_delete: :delete_all), null: true)
    end

    create(
      constraint(:tool_refs, :must_have_at_least_one_tool,
        check: """
        alliance_tool_id != null or
        feldspar_tool_id != null or
        document_tool_id != null or
        lab_tool_id != null or
        graphite_tool_id != null or
        instruction_tool_id != null or
        onyx_tool_id != null
        """
      )
    )

    alter table(:workflows) do
      remove(:type)
    end
  end

  def down do
    alter table(:workflows) do
      add(:type, :string)
    end

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      remove(:onyx_tool_id)
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

    drop(table(:onyx_label))
    drop(table(:onyx_criterion))
    drop(table(:onyx_criterion_group))
    drop(table(:onyx_ris))
    drop(table(:onyx_file_paper))
    drop(table(:onyx_file_error))
    drop(table(:onyx_tool_file))
    drop(table(:onyx_paper))
    drop(table(:onyx_tool))
  end
end
