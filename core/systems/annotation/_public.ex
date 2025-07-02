defmodule Systems.Annotation.Public do
  use Core, :auth
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset, only: [put_assoc: 3]
  import Systems.Annotation.Queries

  import Systems.Ontology.Public,
    only: [upsert_ontology_ref: 3, obtain_concept!: 2, obtain_ontology_ref!: 1]

  alias Core.Repo
  alias Ecto.Multi
  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  @annotation :annotation
  @annotation_resource :annotation_resource
  @annotation_entity :annotation_entity
  @annotation_ref :annotation_ref
  @annotation_sub :annotation_sub
  @ontology_ref :ontology_ref
  @ontology_concept :ontology_concept
  @ontology_predicate :ontology_predicate

  def get_annotation(id) do
    Repo.get(Annotation.Model, id)
  end

  def get_annotation(type, statement, entity) do
    Repo.one(
      from(a in Annotation.Model,
        as: :annotation,
        where: a.type_id == ^type.id and a.statement == ^statement and a.entity_id == ^entity.id
      )
    )
  end

  def list_annotations(entities, preloads) when is_list(entities) do
    annotation_query()
    |> annotation_query_include(:entities, entities)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_annotations({%Annotation.Model{} = annotation, entities}, preloads)
      when is_list(entities) do
    annotation_query()
    |> annotation_query_include(:entities, entities)
    |> annotation_query_join(:annotation_ref)
    |> annotation_query_include(:reference, {annotation, entities})
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_annotations({%Ontology.ConceptModel{} = concept, entities}, preloads)
      when is_list(entities) do
    annotation_query()
    |> annotation_query_include(:entities, entities)
    |> annotation_query_join(:annotation_ref)
    |> annotation_query_include(:reference, {concept, entities})
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_annotations({%Ontology.PredicateModel{} = predicate, entities}, preloads)
      when is_list(entities) do
    annotation_query()
    |> annotation_query_include(:entities, entities)
    |> annotation_query_join(:annotation_ref)
    |> annotation_query_include(:reference, {predicate, entities})
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def insert_annotation!(
        type_phrase,
        statement,
        ref_type_phrase,
        %Ontology.ConceptModel{} = concept,
        %Authentication.Entity{} = entity
      )
      when is_binary(type_phrase) and is_binary(ref_type_phrase) and is_binary(statement) do
    type = obtain_concept!(type_phrase, entity)
    annotation_ref = obtain_annotation_ref!({:concept, {ref_type_phrase, concept}}, entity)
    insert_annotation!(type, statement, entity, [annotation_ref], [])
  end

  def insert_annotation!(type, statement, %Authentication.Entity{} = entity, references, opts)
      when is_list(references) do
    case insert_annotation(type, statement, entity, references, opts) do
      {:ok, annotation} ->
        annotation

      _error ->
        raise "Failed to insert annotation"
    end
  end

  def insert_annotation(type, statement, entity, references, opts) when is_list(references) do
    prepare_annotation(type, references, statement, entity, opts)
    |> Repo.insert()
  end

  def insert_annotation(type, statement, entity, %Annotation.RefModel{} = ref, opts) do
    Multi.new()
    |> Multi.put(@annotation_ref, ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, ref_type, assoc, opts \\ [])

  def insert_annotation(type, statement, entity, ref_type, resource, opts)
      when is_binary(resource) do
    Multi.new()
    |> upsert_resource(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        ref_type,
        %Annotation.ResourceModel{} = resource,
        opts
      ) do
    Multi.new()
    |> Multi.put(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, ref_type, %Authentication.Entity{} = ref, opts) do
    Multi.new()
    |> Multi.put(@annotation_entity, ref)
    |> upsert_annotation_ref(@annotation_ref, @annotation_entity, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, ref_type, %Annotation.Model{} = ref, opts) do
    Multi.new()
    |> Multi.put(@annotation_sub, ref)
    |> upsert_annotation_ref(@annotation_ref, @annotation_sub, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        ref_type,
        %Ontology.RefModel{} = ontology_ref,
        opts
      ) do
    Multi.new()
    |> Multi.put(@ontology_ref, ontology_ref)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        ref_type,
        %Ontology.ConceptModel{} = concept,
        opts
      ) do
    Multi.new()
    |> Multi.put(@ontology_concept, concept)
    |> upsert_ontology_ref(@ontology_ref, @ontology_concept)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        ref_type,
        %Ontology.PredicateModel{} = predicate,
        opts
      ) do
    Multi.new()
    |> Multi.put(@ontology_predicate, predicate)
    |> upsert_ontology_ref(@ontology_ref, @ontology_predicate)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        %Multi{} = multi,
        multi_name,
        multi_child_name,
        type,
        statement,
        entity,
        opts
      ) do
    Multi.insert(
      multi,
      multi_name,
      fn multi_state ->
        child = Map.get(multi_state, multi_child_name)
        prepare_annotation(type, [child], statement, entity, opts)
      end
    )
  end

  def prepare_annotation(
        %Ontology.ConceptModel{} = type,
        references,
        statement,
        entity,
        opts \\ []
      )
      when is_list(references) do
    ai_generated? = Keyword.get(opts, :ai_generated?, false)

    %Annotation.Model{}
    |> Annotation.Model.changeset(%{
      statement: statement,
      ai_generated?: ai_generated?
    })
    |> put_assoc(:type, type)
    |> put_assoc(:references, references)
    |> put_assoc(:entity, entity)
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
      conflict_target: [:type_id, :entity_id, :resource_id, :annotation_id, :ontology_ref_id],
      on_conflict: {:replace_all_except, [:id]}
    )
  end

  def obtain_annotation_ref!(
        {:concept, {type_phrase, %Ontology.ConceptModel{} = concept}},
        entity
      )
      when is_binary(type_phrase) do
    type = obtain_concept!(type_phrase, entity)
    ontology_ref = obtain_ontology_ref!(concept)
    obtain_annotation_ref!(type, ontology_ref)
  end

  def obtain_annotation_ref!(
        {:annotation, {type_phrase, %Annotation.Model{} = annotation}},
        entity
      )
      when is_binary(type_phrase) do
    type = obtain_concept!(type_phrase, entity)
    obtain_annotation_ref!(type, annotation)
  end

  def obtain_annotation_ref!(type, assoc) do
    case obtain_annotation_ref(type, assoc) do
      {:ok, %{annotation_ref: annotation_ref}} ->
        annotation_ref

      _ ->
        raise "Failed to obtain annotation ref"
    end
  end

  def obtain_annotation_ref(type, assoc) do
    Multi.new()
    |> Multi.put(@annotation_sub, assoc)
    |> upsert_annotation_ref(@annotation_ref, @annotation_sub, type)
    |> Repo.transaction()
  end

  def prepare_annotation_ref(type, %Authentication.Entity{} = entity) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:type, type)
    |> put_assoc(:entity, entity)
  end

  def prepare_annotation_ref(type, %Annotation.ResourceModel{} = resource) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:type, type)
    |> put_assoc(:resource, resource)
  end

  def prepare_annotation_ref(type, %Annotation.Model{} = annotation) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:type, type)
    |> put_assoc(:annotation, annotation)
  end

  def prepare_annotation_ref(type, %Ontology.RefModel{} = ontology_ref) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:type, type)
    |> put_assoc(:ontology_ref, ontology_ref)
  end

  def upsert_resource(%Multi{} = multi, multi_name, value) when is_binary(value) do
    Multi.insert(
      multi,
      multi_name,
      prepare_resource(value),
      conflict_target: [:value],
      on_conflict: {:replace_all_except, [:id]}
    )
  end

  def prepare_resource(value) do
    %Annotation.ResourceModel{}
    |> Annotation.ResourceModel.changeset(%{value: value})
  end

  def obtain_annotation(pattern) do
    Systems.Annotation.Pattern.obtain(pattern)
  end

  def summarize(%Annotation.RefModel{
        ontology_ref: %Ontology.RefModel{concept: %Ontology.ConceptModel{phrase: phrase}}
      }) do
    phrase
  end

  def get_most_recent_definition(
        %Ontology.ConceptModel{} = concept,
        %Authentication.Entity{} = entity
      ) do
    {:ok, query} =
      %Annotation.Pattern.Definition{
        subject: concept,
        entity: entity
      }
      |> Annotation.Pattern.query()

    query
    |> Repo.all()
    |> Enum.sort_by(& &1.inserted_at, :desc)
    |> case do
      [annotation | _] ->
        annotation.statement

      _ ->
        dgettext("eyra-annotation", "definition.placeholder", phrase: concept.phrase)
    end
  end
end
