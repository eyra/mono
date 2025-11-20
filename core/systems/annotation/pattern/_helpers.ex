defmodule Systems.Annotation.Pattern.Helpers do
  defmacro __using__(_opts) do
    quote do
      use Systems.Annotation.Constants

      import Systems.Annotation.Queries
      import Systems.Annotation.Public, only: [insert_annotation!: 4, obtain_annotation_ref!: 1]
      import Systems.Ontology.Public, only: [obtain_concept!: 2, obtain_ontology_ref!: 1]

      alias Core.Repo
      alias Systems.Annotation
      alias Systems.Annotation.Pattern.MissingFieldError
      alias Systems.Ontology
      alias Systems.Ontology.ConceptModel
      alias Systems.Ontology.PredicateModel
      alias Systems.Account.User

      def query_annotation(type_phrase, statement, entity, reference_target) do
        query_annotation(type_phrase, statement, entity)
        |> annotation_query_include(:reference, reference_target)
      end

      def query_annotation(type_phrase, statement, entity) do
        annotation_query()
        |> annotation_query_include(:statement, statement)
        |> annotation_query_include(:entity, entity)
        |> annotation_query_join(:annotation_ref)
      end
    end
  end
end
