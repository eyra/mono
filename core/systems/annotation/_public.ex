defmodule Systems.Annotation.Public do
  use Core, :auth

  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset, only: [put_assoc: 3]

  import Systems.Ontology.Public,
    only: [upsert_ontology_ref: 3, obtain_concept!: 2, obtain_ontology_ref!: 1]

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Account
  alias Systems.Annotation
  alias Systems.Ontology

  @annotation :annotation
  @annotation_resource :annotation_resource
  @annotation_user :annotation_user
  @annotation_ref :annotation_ref
  @annotation_sub :annotation_sub
  @ontology_ref :ontology_ref
  @ontology_concept :ontology_concept
  @ontology_predicate :ontology_predicate

  def get_annotation(type, statement, user) do
    Repo.one(
      from(a in Annotation.Model,
        as: :annotation,
        where: a.type_id == ^type.id and a.statement == ^statement and a.author_id == ^user.id
      )
    )
  end

  def insert_annotation!(
        type_phrase,
        statement,
        ref_type_phrase,
        %Ontology.ConceptModel{} = concept,
        %Account.User{} = author
      )
      when is_binary(type_phrase) and is_binary(ref_type_phrase) and is_binary(statement) do
    type = obtain_concept!(type_phrase, author)
    annotation_ref = obtain_annotation_ref!({:concept, {ref_type_phrase, concept}}, author)
    insert_annotation!(type, statement, author, [annotation_ref], [])
  end

  def insert_annotation!(type, statement, %Account.User{} = user, references, opts)
      when is_list(references) do
    case insert_annotation(type, statement, user, references, opts) do
      {:ok, annotation} ->
        annotation

      _error ->
        raise "Failed to insert annotation"
    end
  end

  def insert_annotation(type, statement, user, references, opts) when is_list(references) do
    prepare_annotation(type, references, statement, user, opts)
    |> Repo.insert()
  end

  def insert_annotation(type, statement, user, %Annotation.RefModel{} = ref, opts) do
    Multi.new()
    |> Multi.put(@annotation_ref, ref)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, user, ref_type, assoc, opts \\ [])

  def insert_annotation(type, statement, user, ref_type, resource, opts)
      when is_binary(resource) do
    Multi.new()
    |> upsert_resource(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        user,
        ref_type,
        %Annotation.ResourceModel{} = resource,
        opts
      ) do
    Multi.new()
    |> Multi.put(@annotation_resource, resource)
    |> upsert_annotation_ref(@annotation_ref, @annotation_resource, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, user, ref_type, %Account.User{} = user, opts) do
    Multi.new()
    |> Multi.put(@annotation_user, user)
    |> upsert_annotation_ref(@annotation_ref, @annotation_user, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, user, ref_type, %Annotation.Model{} = ref, opts) do
    Multi.new()
    |> Multi.put(@annotation_sub, ref)
    |> upsert_annotation_ref(@annotation_ref, @annotation_sub, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        user,
        ref_type,
        %Ontology.RefModel{} = ontology_ref,
        opts
      ) do
    Multi.new()
    |> Multi.put(@ontology_ref, ontology_ref)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(type, statement, user, ref_type, %Ontology.ConceptModel{} = concept, opts) do
    Multi.new()
    |> Multi.put(@ontology_concept, concept)
    |> upsert_ontology_ref(@ontology_ref, @ontology_concept)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        type,
        statement,
        user,
        ref_type,
        %Ontology.PredicateModel{} = predicate,
        opts
      ) do
    Multi.new()
    |> Multi.put(@ontology_predicate, predicate)
    |> upsert_ontology_ref(@ontology_ref, @ontology_predicate)
    |> upsert_annotation_ref(@annotation_ref, @ontology_ref, ref_type)
    |> insert_annotation(@annotation, @annotation_ref, type, statement, user, opts)
    |> Repo.transaction()
  end

  def insert_annotation(
        %Multi{} = multi,
        multi_name,
        multi_child_name,
        type,
        statement,
        user,
        opts
      ) do
    Multi.insert(
      multi,
      multi_name,
      fn multi_state ->
        child = Map.get(multi_state, multi_child_name)
        prepare_annotation(type, [child], statement, user, opts)
      end
    )
  end

  def prepare_annotation(%Ontology.ConceptModel{} = type, references, statement, user, opts \\ [])
      when is_list(references) do
    ai_generated? = Keyword.get(opts, :ai_generated?, false)

    %Annotation.Model{}
    |> Annotation.Model.changeset(%{
      statement: statement,
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
      conflict_target: [:type_id, :user_id, :resource_id, :annotation_id, :ontology_ref_id],
      on_conflict: {:replace_all_except, [:id]}
    )
  end

  def obtain_annotation_ref!(
        {:concept, {type_phrase, %Ontology.ConceptModel{} = concept}},
        author
      )
      when is_binary(type_phrase) do
    type = obtain_concept!(type_phrase, author)
    ontology_ref = obtain_ontology_ref!(concept)
    obtain_annotation_ref!(type, ontology_ref)
  end

  def obtain_annotation_ref!(
        {:annotation, {type_phrase, %Annotation.Model{} = annotation}},
        author
      )
      when is_binary(type_phrase) do
    type = obtain_concept!(type_phrase, author)
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

  def prepare_annotation_ref(type, %Account.User{} = user) do
    %Annotation.RefModel{}
    |> Annotation.RefModel.changeset(%{})
    |> put_assoc(:type, type)
    |> put_assoc(:user, user)
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
end
