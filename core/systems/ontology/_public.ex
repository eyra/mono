defmodule Systems.Ontology.Public do
  use Core, :auth

  import Ecto.Query, only: [order_by: 3]
  import Ecto.Changeset, only: [put_assoc: 3]
  import Systems.Ontology.Queries

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Account
  alias Systems.Ontology

  @ontology_ref_conflict_opts [
    conflict_target: [:concept_id, :predicate_id],
    on_conflict: {:replace_all_except, [:id]}
  ]

  # Concept

  def obtain_concept!(phrase, user) do
    case insert_concept(phrase, user) do
      {:ok, concept} ->
        concept

      {:error,
       %{
         errors: [
           phrase:
             {"has already been taken",
              [constraint: :unique, constraint_name: "ontology_concept_unique"]}
         ]
       }} ->
        get_concept_by_phrase(phrase)
    end
  end

  def get_concept(id) when is_binary(id) do
    concept_query_by_id(id)
    |> Repo.one()
  end

  def get_concept_by_phrase(phrase) when is_binary(phrase) do
    concept_query_by_phrase(phrase)
    |> Repo.one()
  end

  def list_concepts_by_author(%Account.User{} = author) do
    concept_query_by_author(author)
    |> order_by([concept: c], asc: c.id)
    |> Repo.all()
  end

  def insert_concept(phrase, user, opts \\ []) do
    prepare_concept(phrase, user, opts)
    |> Repo.insert()
  end

  def prepare_concept(phrase, user, _opts) do
    %Ontology.ConceptModel{}
    |> Ontology.ConceptModel.changeset(%{phrase: phrase})
    |> put_assoc(:author, user)
    |> Ontology.ConceptModel.validate()
  end

  # Predicate

  def obtain_predicate(subject, subsumes, object, user) do
    case insert_predicate(subject, subsumes, object, user) do
      {:ok, predicate} ->
        predicate

      {:error,
       %{
         errors: [
           subject_id:
             {"has already been taken",
              [constraint: :unique, constraint_name: "ontology_predicate_unique"]}
         ]
       }} ->
        get_predicate(subject, subsumes, object)
    end
  end

  def get_predicate(id) when is_binary(id) do
    predicate_query_by_id(id)
    |> Repo.one()
  end

  def get_predicate(subject, type, object, type_negated? \\ false) do
    predicate_query(subject, type, object, type_negated?)
    |> Repo.one()
  end

  def list_predicates_by_author(%Account.User{} = author) do
    predicate_query_by_author(author)
    |> Repo.all()
  end

  def list_predicates_by_subject(%Ontology.ConceptModel{} = subject) do
    predicate_query_by_subject(subject)
    |> Repo.all()
  end

  def list_predicates_by_type(%Ontology.ConceptModel{} = type) do
    predicate_query_by_type(type)
    |> Repo.all()
  end

  def list_predicates_by_object(%Ontology.ConceptModel{} = object) do
    predicate_query_by_object(object)
    |> Repo.all()
  end

  def insert_predicate(subject, type, object, user, opts \\ []) do
    prepare_predicate(subject, type, object, user, opts)
    |> Repo.insert()
  end

  def prepare_predicate(subject, type, object, user, opts \\ []) do
    type_negated? = Keyword.get(opts, :type_negated?, false)

    %Ontology.PredicateModel{}
    |> Ontology.PredicateModel.changeset(%{type_negated?: type_negated?})
    |> put_assoc(:subject, subject)
    |> put_assoc(:type, type)
    |> put_assoc(:object, object)
    |> put_assoc(:author, user)
    |> Ontology.PredicateModel.validate()
  end

  def upsert_ontology_ref(%Multi{} = multi, multi_name, multi_child_name) do
    Multi.insert(
      multi,
      multi_name,
      fn multi_state ->
        child = Map.get(multi_state, multi_child_name)
        prepare_ontology_ref(child)
      end,
      @ontology_ref_conflict_opts
    )
  end

  def obtain_ontology_ref!(concept_or_predicate) do
    case obtain_ontology_ref(concept_or_predicate) do
      {:ok, %{ontology_ref: ontology_ref}} ->
        ontology_ref

      _ ->
        raise "Failed to obtain ontology ref"
    end
  end

  def obtain_ontology_ref(concept_or_predicate) do
    Multi.new()
    |> Multi.put(:concept_or_predicate, concept_or_predicate)
    |> upsert_ontology_ref(:ontology_ref, :concept_or_predicate)
    |> Repo.transaction()
  end

  def prepare_ontology_ref(%Ontology.ConceptModel{} = concept) do
    %Ontology.RefModel{}
    |> Ontology.RefModel.changeset(%{})
    |> put_assoc(:concept, concept)
  end

  def prepare_ontology_ref(%Ontology.PredicateModel{} = predicate) do
    %Ontology.RefModel{}
    |> Ontology.RefModel.changeset(%{})
    |> put_assoc(:predicate, predicate)
  end
end
