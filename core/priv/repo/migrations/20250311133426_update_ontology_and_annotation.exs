defmodule Systems.Repo.Migrations.UpdateOntologyAndAnnotation do
  use Ecto.Migration

  def change do
    # First rename the term table to concept
    rename table(:ontology_term), to: table(:ontology_concept)

    # Add fields to ontology_concept
    alter table(:ontology_concept) do
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
    end

    # Prevent duplicate concepts
    create(unique_index(:ontology_concept, [:phrase], name: :ontology_concept_unique))

    # Then create the predicate table with all fields in their final form
    create table(:ontology_predicate) do
      add(:type_id, references(:ontology_concept, on_delete: :delete_all), null: false)
      add(:subject_id, references(:ontology_concept, on_delete: :delete_all), null: false)
      add(:object_id, references(:ontology_concept, on_delete: :delete_all), null: false)
      add(:type_negated?, :boolean, default: false, null: false)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      timestamps()
    end

    # Create ontology_predicate indexes
    create(index(:ontology_predicate, [:subject_id]))
    create(index(:ontology_predicate, [:object_id]))
    create(index(:ontology_predicate, [:type_id]))

    # Prevent duplicate predicates
    create(unique_index(:ontology_predicate, [:subject_id, :object_id, :type_id, :author_id, :type_negated?], name: :ontology_predicate_unique_predicate))

    # Force object_id to be different from subject_id
    create(
      constraint(:ontology_predicate, :ontology_predicate_object_different_from_subject,
        check: "object_id != subject_id"
      )
    )

    # Create annotation table
    alter table(:annotation) do
      add(:value, :text, null: false)
      add(:ai_generated?, :boolean, default: false, null: false)
      add(:type_id, references(:ontology_concept, on_delete: :delete_all), null: false)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      remove(:term)
      remove(:description)
    end

    # Prevent duplicate annotations
    create(unique_index(:annotation, [:value, :ai_generated?, :type_id, :author_id], name: :annotation_unique))

    # Create ontology_ref table
    create table(:ontology_ref) do
      add(:concept_id, references(:ontology_concept, on_delete: :delete_all), null: true)
      add(:predicate_id, references(:ontology_predicate, on_delete: :delete_all), null: true)
      timestamps()
    end

    # Force ontology_ref to have at least one association
    create(
      constraint(:ontology_ref, :must_have_at_least_one,
        check: """
        concept_id != null or
        predicate_id != null
        """
      )
    )

    # Create ontology_ref indexes
    create(index(:ontology_ref, [:concept_id]))
    create(index(:ontology_ref, [:predicate_id]))

    # Prevent duplicate ontology_refs
    create(unique_index(:ontology_ref, [:concept_id, :predicate_id], name: :ontology_ref_unique_ref))

    create table(:annotation_ref) do
      add(:type_id, references(:ontology_concept, on_delete: :delete_all), null: false)
      add(:annotation_id, references(:annotation, on_delete: :delete_all), null: true)
      add(:ontology_ref_id, references(:ontology_ref, on_delete: :delete_all), null: true)
      timestamps()
    end

    create(
      constraint(:annotation_ref, :must_have_at_least_one,
        check: """
        annotation_id != null or
        ontology_ref_id != null
        """
      )
    )

    # Create annotation_ref indexes
    create(index(:annotation_ref, [:type_id]))
    create(index(:annotation_ref, [:annotation_id]))
    create(index(:annotation_ref, [:ontology_ref_id]))

    # Prevent duplicate annotation_refs
    create(unique_index(:annotation_ref, [:annotation_id, :ontology_ref_id, :type_id], name: :annotation_ref_unique_ref))

    # Create annotation_assoc table
    create table(:annotation_assoc) do
      add(:annotation_id, references(:annotation, on_delete: :delete_all), null: false)
      add(:ref_id, references(:annotation_ref, on_delete: :delete_all), null: false)
      timestamps()
    end

    # Create annotation_assoc indexes
    create(index(:annotation_assoc, [:annotation_id]))
    create(index(:annotation_assoc, [:ref_id]))
    create(unique_index(:annotation_assoc, [:annotation_id, :ref_id], name: :annotation_assoc_unique_assoc))

  end
end 