defmodule Next.Systems.Annotation.Pattern.Helpers do
  defmacro __using__(_opts) do
    quote do
      use Next.Systems.Annotation.Constants

      import Next.Systems.Annotation.Queries

      import Next.Systems.Annotation.Public,
        only: [insert_annotation!: 4, obtain_annotation_ref!: 1]

      import Next.Systems.Ontology.Public, only: [obtain_concept!: 2, obtain_ontology_ref!: 1]

      alias Mica.Repo
      alias Next.Systems.Annotation
      alias Next.Systems.Annotation.Pattern.MissingFieldError
      alias Next.Systems.Ontology
      alias Next.Systems.Ontology.ConceptModel
      alias Next.Systems.Ontology.PredicateModel
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
