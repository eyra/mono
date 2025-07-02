defmodule Systems.Annotation.Pattern.Helpers do
  defmacro __using__(_opts) do
    quote do
      use Systems.Annotation.Constants

      import Systems.Annotation.Queries
      import Systems.Annotation.Public, only: [insert_annotation!: 5, obtain_annotation_ref!: 2]
      import Systems.Ontology.Public, only: [obtain_concept!: 2, obtain_ontology_ref!: 1]

      alias Core.Repo
      alias Systems.Annotation
      alias Systems.Annotation.Pattern.MissingFieldError
      alias Systems.Ontology
      alias Systems.Ontology.ConceptModel
      alias Systems.Ontology.PredicateModel
      alias Systems.Account.User

      def query_annotation(type_phrase, statement, entity, {:concept, {ref_type_phrase, concept}}) do
        query_annotation(type_phrase, statement, entity, ref_type_phrase)
        |> annotation_query_include(:reference, concept)
      end

      def query_annotation(
            type_phrase,
            statement,
            entity,
            {:annotation, {ref_type_phrase, annotation}}
          ) do
        query_annotation(type_phrase, statement, entity)
        |> annotation_query_include(:annotation, annotation)
      end

      def query_annotation(type_phrase, statement, entity, ref_type_phrase) do
        query_annotation(type_phrase, statement, entity)
        |> annotation_query_include(:annotation_ref_type, ref_type_phrase)
      end

      def query_annotation(type_phrase, statement, entity) do
        annotation_query()
        |> annotation_query_include(:type, type_phrase)
        |> annotation_query_include(:statement, statement)
        |> annotation_query_include(:entity, entity)
        |> annotation_query_join(:annotation_ref)
      end
    end
  end
end
