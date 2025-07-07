defmodule Systems.Ontology.Public do
  use Core, :auth
  use Systems.Ontology.Constants

  import Ecto.Query, only: [order_by: 3, select: 3]
  import Ecto.Changeset, only: [put_assoc: 3]
  import Systems.Ontology.Queries

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Ontology

  @ontology_ref_conflict_opts [
    conflict_target: [:concept_id, :predicate_id],
    on_conflict: {:replace_all_except, [:id]}
  ]

  # Concept
  def obtain_concept!(phrase, entity) do
    case obtain_concept(phrase, entity) do
      {:ok, concept} ->
        concept

      error ->
        raise "Failed to obtain concept: #{inspect(error)}"
    end
  end

  def obtain_concept(phrase, entity) do
    Multi.new()
    |> Multi.run(:concept, fn _, _ ->
      case get_concept(phrase) do
        nil ->
          insert_concept(phrase, entity)

        concept ->
          {:ok, concept}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{concept: concept}} ->
        {:ok, concept}

      error ->
        error
    end
  end

  def query_concept_ids(entities, selector) do
    concept_query(selector)
    |> concept_query_include(:entities, entities)
    |> select([concept: c], c.id)
  end

  def get_concept(_, preloads \\ [])

  def get_concept(id, preloads) when is_integer(id) do
    concept_query(id)
    |> Repo.one()
    |> Repo.preload(preloads)
  end

  def get_concept(phrase, preloads) when is_binary(phrase) do
    concept_query(phrase)
    |> Repo.one()
    |> Repo.preload(preloads)
  end

  def list_concepts(preloads) when is_list(preloads) do
    concept_query()
    |> order_by([concept: c], asc: c.id)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_concepts(phrases, preloads) when is_list(phrases) and is_list(preloads) do
    concept_query(phrases)
    |> order_by([concept: c], asc: c.id)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def insert_concept(phrase, entity, opts \\ []) do
    prepare_concept(phrase, entity, opts)
    |> Repo.insert()
  end

  def prepare_concept(phrase, entity, _opts) do
    %Ontology.ConceptModel{}
    |> Ontology.ConceptModel.changeset(%{phrase: phrase})
    |> put_assoc(:entity, entity)
    |> Ontology.ConceptModel.validate()
  end

  # Predicate

  def obtain_predicate!(subject, subsumes, object, entity) do
    {:ok, predicate} = obtain_predicate(subject, subsumes, object, entity)
    predicate
  end

  def obtain_predicate(subject, subsumes, object, entity) do
    Multi.new()
    |> Multi.run(:predicate, fn _, _ ->
      case get_predicate({subject, subsumes, object, false}) do
        nil ->
          insert_predicate(subject, subsumes, object, entity)

        predicate ->
          {:ok, predicate}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{predicate: predicate}} ->
        {:ok, predicate}

      error ->
        error
    end
  end

  def query_predicate_ids(selector) do
    predicate_query(selector)
    |> select([predicate: p], p.id)
  end

  def get_predicate(selector, preloads \\ []) do
    predicate_query(selector)
    |> Repo.one()
    |> Repo.preload(preloads)
  end

  def list_predicates(preloads) do
    predicate_query()
    |> order_by([predicate: p], asc: p.id)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_predicates(%Ontology.ConceptModel{} = concept, preloads) do
    predicate_query(concept)
    |> order_by([predicate: p], asc: p.id)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def insert_predicate(subject, type, object, entity, opts \\ []) do
    prepare_predicate(subject, type, object, entity, opts)
    |> Repo.insert()
  end

  def prepare_predicate(subject, type, object, entity, opts \\ []) do
    type_negated? = Keyword.get(opts, :type_negated?, false)

    %Ontology.PredicateModel{}
    |> Ontology.PredicateModel.changeset(%{type_negated?: type_negated?})
    |> put_assoc(:subject, subject)
    |> put_assoc(:type, type)
    |> put_assoc(:object, object)
    |> put_assoc(:entity, entity)
    |> Ontology.PredicateModel.validate()
  end

  # Ref

  def query_ref_ids(selector) do
    ref_query(selector)
    |> select([ref: r], r.id)
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
      {:ok, ontology_ref} ->
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
    |> case do
      {:ok, %{ontology_ref: ontology_ref}} ->
        {:ok, ontology_ref}

      error ->
        error
    end
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

  # Helper functions based on primitive concepts and predicates

  def get_members_of_category(object) when is_binary(object) do
    predicate_query(%{object: object, type: @subsumes})
    |> Repo.all()
    |> Repo.preload([:subject])
    |> Enum.map(fn predicate -> predicate.subject end)
    |> Enum.uniq()
  end

  def get_categories_for_member(subject) when is_binary(subject) do
    predicate_query(%{subject: subject, type: @subsumes})
    |> Repo.all()
    |> Repo.preload([:object])
    |> Enum.map(fn predicate -> predicate.object end)
    |> Enum.uniq()
  end
end
