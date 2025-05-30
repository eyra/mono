defmodule Systems.Ontology.Queries do
    import Ecto.Query
    require Frameworks.Utility.Query

    import Frameworks.Utility.Query, only: [build: 3]

    alias Systems.Account
    alias Systems.Ontology

    # CONCEPT
    def concept_query() do
        from(c in Ontology.ConceptModel, as: :concept)
    end

    def concept_query_by_id(id) when is_binary(id) do
        build(concept_query(), :concept, [id == ^id])
    end

    def concept_query_by_phrase(phrase) when is_binary(phrase) do
        build(concept_query(), :concept, [phrase == ^phrase]  )
    end

    def concept_query_by_author(%Account.User{id: user_id}) do
        build(concept_query(), :concept, [author_id == ^user_id])
    end

    # PREDICATE

    def predicate_query() do
        from(p in Ontology.PredicateModel, as: :predicate)
    end

    def predicate_query_by_id(id) when is_binary(id) do
        build(predicate_query(), :predicate, id == ^id)
    end

    def predicate_query_by_subject(%Ontology.ConceptModel{} = subject) do
        build(predicate_query(), :predicate, subject_id == ^subject.id)
        |> order_by([predicate: p], asc: p.id)
    end

    def predicate_query_by_type(%Ontology.ConceptModel{} = type) do
        build(predicate_query(), :predicate, type_id == ^type.id)
        |> order_by([predicate: p], asc: p.id)
    end

    def predicate_query_by_object(%Ontology.ConceptModel{} = object) do
        build(predicate_query(), :predicate, object_id == ^object.id)
        |> order_by([predicate: p], asc: p.id)
    end

    def predicate_query_by_author(%Account.User{id: user_id}) do
        build(predicate_query(), :predicate, author_id == ^user_id)
        |> order_by([predicate: p], asc: p.id)
    end
end