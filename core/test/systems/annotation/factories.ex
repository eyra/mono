defmodule Systems.Annotation.Factories do
  alias Core.Factories
  alias Systems.Annotation
  alias Systems.Ontology

  def insert_annotation(type, value, author, target)

  def insert_annotation(
        %Ontology.ConceptModel{} = type,
        value,
        %{} = author,
        %Annotation.Model{} = annotation
      ) do
    reference = insert_annotation_ref(annotation)

    Factories.insert!(:annotation, %{
      type: type,
      value: value,
      author: author,
      references: [reference]
    })
  end

  def insert_annotation(
        %Ontology.ConceptModel{} = type,
        value,
        %{} = author,
        %Ontology.ConceptModel{} = concept
      ) do
    ontology_ref = Ontology.Factories.insert_ref(concept)
    reference = insert_annotation_ref(ontology_ref)

    Factories.insert!(:annotation, %{
      type: type,
      value: value,
      author: author,
      references: [reference]
    })
  end

  def insert_annotation(
        %Ontology.ConceptModel{} = type,
        value,
        %{} = author,
        %Ontology.PredicateModel{} = predicate
      ) do
    ontology_ref = Ontology.Factories.insert_ref(predicate)
    reference = insert_annotation_ref(ontology_ref)

    Factories.insert!(:annotation, %{
      type: type,
      value: value,
      author: author,
      references: [reference]
    })
  end

  def insert_annotation_ref(%Ontology.RefModel{} = ontology_ref) do
    Factories.insert!(:annotation_ref, %{ontology_ref: ontology_ref})
  end

  def insert_annotation_ref(%Annotation.Model{} = annotation) do
    Factories.insert!(:annotation_ref, %{annotation: annotation})
  end
end
