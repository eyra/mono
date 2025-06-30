defmodule Core.Repo.Migrations.UpdateOntologyGlobalSharing do
  use Ecto.Migration

  def up do
    # Drop the old entity-scoped predicate uniqueness constraint
    drop_if_exists(
      unique_index(
        :ontology_predicate,
        [:subject_id, :object_id, :type_id, :entity_id, :type_negated?],
        name: :ontology_predicate_unique
      )
    )

    # Create new global predicate uniqueness constraint (without entity_id)
    create(
      unique_index(
        :ontology_predicate,
        [:subject_id, :object_id, :type_id, :type_negated?],
        name: :ontology_predicate_unique
      )
    )
  end

  def down do
    # Drop the global predicate uniqueness constraint
    drop_if_exists(
      unique_index(
        :ontology_predicate,
        [:subject_id, :object_id, :type_id, :type_negated?],
        name: :ontology_predicate_unique
      )
    )

    # Restore the old entity-scoped predicate uniqueness constraint
    create(
      unique_index(
        :ontology_predicate,
        [:subject_id, :object_id, :type_id, :entity_id, :type_negated?],
        name: :ontology_predicate_unique
      )
    )
  end
end