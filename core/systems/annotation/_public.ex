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
        %Ontology.ConceptModel{} = concept,
        %Authentication.Entity{} = entity
      )
      when is_binary(type_phrase) and is_binary(statement) do
    type = obtain_concept!(type_phrase, entity)
    annotation_ref = obtain_annotation_ref!(concept)
    insert_annotation!(type, statement, entity, [annotation_ref])
  end

  def insert_annotation!(type, statement, %Authentication.Entity{} = entity, references)
      when is_list(references) do
    case insert_annotation(type, statement, entity, references) do
      {:ok, annotation} ->
        annotation

      error ->
        raise "Failed to insert annotation: #{inspect(error)}"
    end
  end

  def insert_annotation(type, statement, entity, references) when is_list(references) do
    prepare_annotation(type, references, statement, entity)
    |> Repo.insert()
  end

  def insert_annotation(type, statement, entity, %Annotation.RefModel{} = ref) do
    Multi.new()
    |> Multi.put(@annotation_ref, ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, resource)
      when is_binary(resource) do
    Multi.new()
    |> upsert_resource(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        %Annotation.ResourceModel{} = resource
      ) do
    Multi.new()
    |> Multi.put(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, %Authentication.Entity{} = ref) do
    Multi.new()
    |> Multi.put(@annotation_entity, ref)
    |> upsert_annotation_ref(@annotation_ref, @annotation_entity)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, entity, %Annotation.Model{} = ref) do
    Multi.new()
    |> Multi.put(@annotation_sub, ref)
    |> upsert_annotation_ref(@annotation_ref, @annotation_sub)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        %Ontology.RefModel{} = ontology_ref
      ) do
    Multi.new()
    |> Multi.put(@ontology_ref, ontology_ref)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        %Ontology.ConceptModel{} = concept
      ) do
    Multi.new()
    |> Multi.put(@ontology_concept, concept)
    |> upsert_ontology_ref(@ontology_ref, @ontology_concept)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        entity,
        %Ontology.PredicateModel{} = predicate
      ) do
    Multi.new()
    |> Multi.put(@ontology_predicate, predicate)
    |> upsert_ontology_ref(@ontology_ref, @ontology_predicate)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, entity)
    |> Repo.transaction()
  end

  def insert_annotation(
        %Multi{} = multi,
        multi_name,
        multi_child_name,
        type,
        statement,
        entity
      ) do
    Multi.insert(
      multi,
      multi_name,
      fn multi_state ->
        child = Map.get(multi_state, multi_child_name)
        prepare_annotation(type, [child], statement, entity)
      end
    )
  end

  def prepare_annotation(
        %Ontology.ConceptModel{} = type,
        references,
        statement,
        entity
      )
      when is_list(references) do
    %Annotation.Model{}
    |> Annotation.Model.changeset(%{
      statement: statement
    })
    |> put_assoc(:type, type)
    |> put_assoc(:references, references)
    |> put_assoc(:entity, entity)
    |> Annotation.Model.validate()
  end

  def upsert_annotation_ref(%Multi{} = multi, multi_name, multi_child_name) do
    Multi.insert(
      multi,
      multi_name,
      fn multi_state ->
        child = Map.get(multi_state, multi_child_name)
        prepare_annotation_ref(child)
      end,
      conflict_target: [:entity_id, :resource_id, :annotation_id, :ontology_ref_id],
      on_conflict: {:replace_all_except, [:id]}
    )
  end

  def obtain_annotation_ref!(%Ontology.ConceptModel{} = concept) do
    ontology_ref = obtain_ontology_ref!(concept)
    obtain_annotation_ref!(ontology_ref)
  end

  def obtain_annotation_ref!(%Ontology.PredicateModel{} = predicate) do
    ontology_ref = obtain_ontology_ref!(predicate)
    obtain_annotation_ref!(ontology_ref)
  end

  def obtain_annotation_ref!(assoc) do
    case obtain_annotation_ref(assoc) do
      {:ok, annotation_ref} ->
        annotation_ref

      error ->
        raise "Failed to obtain annotation ref: #{inspect(error)}"
    end
  end

  def obtain_annotation_ref(assoc) do
    Multi.new()
    |> Multi.put(@annotation_sub, assoc)
    |> upsert_annotation_ref(@annotation_ref, @annotation_sub)
    |> Repo.transaction()
    |> case do
      {:ok, %{annotation_ref: annotation_ref}} ->
        {:ok, annotation_ref}

      error ->
        error
    end
  end

  def prepare_annotation_ref(%Authentication.Entity{} = entity) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:entity, entity)
  end

  def prepare_annotation_ref(%Annotation.ResourceModel{} = resource) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:resource, resource)
  end

  def prepare_annotation_ref(%Annotation.Model{} = annotation) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:annotation, annotation)
  end

  def prepare_annotation_ref(%Ontology.RefModel{} = ontology_ref) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
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

  def member?(annotations, %Ontology.ConceptModel{} = concept) when is_list(annotations) do
    Enum.any?(annotations, fn %Annotation.Model{} = annotation ->
      member?(annotation, concept)
    end)
  end

  def member?(%Annotation.Model{} = annotation, %Ontology.ConceptModel{} = concept) do
    Ontology.Element.flatten(annotation)
    |> Enum.filter(fn %module{} -> module == Ontology.ConceptModel end)
    |> Enum.any?(&(&1.phrase == concept.phrase))
  end
end
