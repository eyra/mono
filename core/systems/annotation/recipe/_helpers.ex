defmodule Systems.Annotation.Recipe.Helpers do
  defmacro __using__(_opts) do
    quote do
      use Systems.Annotation.Constants

      import Systems.Annotation.Queries
      import Systems.Annotation.Public, only: [insert_annotation!: 5, obtain_annotation_ref!: 2]
      import Systems.Ontology.Public, only: [obtain_concept!: 2, obtain_ontology_ref!: 1]

      alias Core.Repo
      alias Systems.Annotation
      alias Systems.Annotation.Recipe.MissingFieldError
      alias Systems.Ontology
      alias Systems.Ontology.ConceptModel
      alias Systems.Ontology.PredicateModel
      alias Systems.Account.User

      def query_annotation(type_phrase, statement, author, {:concept, {ref_type_phrase, concept}}) do
        query_annotation(type_phrase, statement, author, ref_type_phrase)
        |> annotation_query_include(:ontology_concept, concept)
      end

      def query_annotation(
            type_phrase,
            statement,
            author,
            {:annotation, {ref_type_phrase, annotation}}
          ) do
        query_annotation(type_phrase, statement, author)
        |> annotation_query_include(:annotation, annotation)
      end

      def query_annotation(type_phrase, statement, author, ref_type_phrase) do
        query_annotation(type_phrase, statement, author)
        |> annotation_query_include(:annotation_ref_type, ref_type_phrase)
      end

      def query_annotation(type_phrase, statement, author) do
        annotation_query()
        |> annotation_query_include(:type, type_phrase)
        |> annotation_query_include(:statement, statement)
        |> annotation_query_include(:author, author)
        |> annotation_query_include(:annotation_ref, true)
      end
    end
  end
end
