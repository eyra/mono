defmodule Core.Repo.Migrations.RefactorOnyxToZircon do
  use Ecto.Migration

  def up do
    drop(table(:onyx_label))
    drop(table(:onyx_criterion))
    drop(table(:onyx_criterion_group))

    rename(table(:onyx_tool), to: table(:zircon_screening_tool))
    rename(table(:onyx_paper), to: table(:paper))
    rename(table(:onyx_tool_file), to: table(:paper_reference_file))
    rename(table(:onyx_file_paper), to: table(:paper_reference_file_paper))
    rename(table(:onyx_file_error), to: table(:paper_reference_file_error))
    rename(table(:onyx_ris), to: table(:paper_ris))

    alter(table(:paper_reference_file)) do
      remove(:tool_id)
    end

    rename(table(:paper_reference_file_paper), :tool_file_id, to: :reference_file_id)
    rename(table(:paper_reference_file_error), :tool_file_id, to: :reference_file_id)

    drop(constraint(:tool_refs, :must_have_at_least_one_tool))

    alter table(:tool_refs) do
      remove(:onyx_tool_id)

      add(:zircon_screening_tool_id, references(:zircon_screening_tool, on_delete: :delete_all),
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
        instruction_tool_id != null or
        zircon_screening_tool_id != null
        """
      )
    )

    create(table(:ontology_term)) do
      add(:phrase, :string)
      timestamps()
    end

    create(table(:annotation)) do
      add(:term, references(:ontology_term, on_delete: :delete_all))
      add(:description, :string)
      timestamps()
    end

    create(table(:zircon_screening_tool_annotation)) do
      add(:tool_id, references(:zircon_screening_tool, on_delete: :delete_all))
      add(:annotation_id, references(:annotation, on_delete: :delete_all))
      timestamps()
    end

    create(table(:zircon_screening_tool_reference_file)) do
      add(:tool_id, references(:zircon_screening_tool, on_delete: :delete_all))
      add(:reference_file_id, references(:paper_reference_file, on_delete: :delete_all))
      timestamps()
    end
  end

  def down do
    drop(table(:zircon_screening_tool_reference_file))
    drop(table(:zircon_screening_tool_annotation))
    drop(table(:annotation))
    drop(table(:ontology_term))

    rename(table(:zircon_screening_tool), to: table(:onyx_tool))

    alter table(:tool_refs) do
      remove(:zircon_screening_tool_id)
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

    rename(table(:paper), to: table(:onyx_paper))
    rename(table(:paper_reference_file), to: table(:onyx_tool_file))
    rename(table(:paper_reference_file_paper), to: table(:onyx_file_paper))
    rename(table(:paper_reference_file_error), to: table(:onyx_file_error))
    rename(table(:paper_ris), to: table(:onyx_ris))

    alter(table(:onyx_tool_file)) do
      add(:tool_id, references(:onyx_tool, on_delete: :delete_all))
    end

    rename(table(:onyx_file_paper), :reference_file_id, to: :tool_file_id)
    rename(table(:onyx_file_error), :reference_file_id, to: :tool_file_id)

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
  end
end
