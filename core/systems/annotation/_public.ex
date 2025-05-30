defmodule Systems.Annotation.Public do
    use Core, :auth

    import Ecto.Changeset, only: [put_assoc: 3]
    import Systems.Ontology.Public, only: [upsert_ontology_ref: 3]

    alias Core.Repo
    alias Ecto.Multi
    alias Systems.Annotation
    alias Systems.Ontology

    @annotation :annotation
    @annotation_ref :annotation_ref
    @annotation_sub :annotation_sub
    @ontology_ref :ontology_ref
    @ontology_concept :ontology_concept
    @ontology_predicate :ontology_predicate

    @annotation_ref_conflict_opts [conflict_target: [:type_id, :annotation_id, :ontology_ref_id],    on_conflict: {:replace_all_except, [:id]}]

    def insert_annotation(type, value, user, references, opts) when is_list(references) do
        prepare_annotation(type, references, value, user, opts)
    end

    def insert_annotation(type, value, user, %Annotation.Ref{} = ref, opts) do
        Multi.new()
        |> Multi.put(@annotation_ref, ref)
        |> insert_annotation(@annotation, @annotation_ref, type, value, user, opts)
        |> Repo.transaction()
    end

    def insert_annotation(type, value, user, ref_type, assoc, opts \\ [])

    def insert_annotation(type, value, user, ref_type, %Annotation.Model{} = ref, opts) do
        Multi.new()
        |> Multi.put(@annotation_sub, ref)
        |> upsert_annotation_ref(@annotation_ref, @annotation_sub, ref_type)
        |> insert_annotation(@annotation, @annotation_ref, type, value, user, opts)
        |> Repo.transaction()
    end

    def insert_annotation(type, value, user, ref_type, %Ontology.Ref{} = ontology_ref, opts) do
        Multi.new()
        |> Multi.put(@ontology_ref, ontology_ref)
        |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
        |> insert_annotation(@annotation, @annotation_ref, type, value, user, opts)
        |> Repo.transaction()
    end

    def insert_annotation(type, value, user, ref_type, %Ontology.ConceptModel{} = concept, opts) do
        Multi.new()
        |> Multi.put(@ontology_concept, concept)
        |> upsert_ontology_ref(@ontology_ref, @ontology_concept)
        |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
        |> insert_annotation(@annotation, @annotation_ref, type, value, user, opts)
        |> Repo.transaction()
    end

    def insert_annotation(type, value, user, ref_type, %Ontology.PredicateModel{} = predicate, opts) do
        Multi.new()
        |> Multi.put(@ontology_predicate, predicate)
        |> upsert_ontology_ref(@ontology_ref, @ontology_predicate)
        |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
        |> insert_annotation(@annotation, @annotation_ref, type, value, user, opts)
        |> Repo.transaction()
    end

    def insert_annotation(%Multi{} = multi, multi_name, multi_child_name, type, value, user, opts) do
        Multi.insert(
            multi, 
            multi_name, 
            fn multi_state ->
                child = Map.get(multi_state, multi_child_name)
                prepare_annotation(type, [child], value, user, opts)
            end
        )
    end

    def prepare_annotation(%Ontology.ConceptModel{} = type, references, value, user, opts \\ []) when is_list(references) do
        ai_generated? = Keyword.get(opts, :ai_generated?, false)

        %Annotation.Model{}
        |> Annotation.Model.changeset(%{
            value: value, 
            ai_generated?: ai_generated?
        })
        |> put_assoc(:type, type)
        |> put_assoc(:references, references)
        |> put_assoc(:author, user)
        |> Annotation.Model.validate()
    end

    def upsert_annotation_ref(%Multi{} = multi, multi_name, multi_child_name, type) do
        Multi.insert(
            multi, 
            multi_name, 
            fn multi_state ->
                child = Map.get(multi_state, multi_child_name)
                prepare_annotation_ref(type, child)
            end, 
            @annotation_ref_conflict_opts
        )
    end

    def prepare_annotation_ref(type, %Annotation.Model{} = annotation) do
        %Annotation.Ref{}
        |> Annotation.Ref.changeset(%{})
        |> put_assoc(:type, type)
        |> put_assoc(:annotation, annotation)
    end

    def prepare_annotation_ref(type, %Ontology.Ref{} = ontology_ref) do
        %Annotation.Ref{}
        |> Annotation.Ref.changeset(%{})
        |> put_assoc(:type, type)
        |> put_assoc(:ontology_ref, ontology_ref)

    end
end