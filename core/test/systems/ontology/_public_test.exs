defmodule Ontology.PublicTest do
  use Core.DataCase

  alias Core.Repo
  import Systems.Ontology.Public
  alias Systems.Ontology

  describe "insert_concept/3" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      %{entity: entity}
    end

    test "insert", %{entity: entity} do
      assert {:ok, %Ontology.ConceptModel{}} = insert_concept("Gravitational Force", entity)
    end

    test "insert + insert (different phrases)", %{entity: entity} do
      {:ok, %{id: id1}} = insert_concept("Gravitational Force", entity)
      {:ok, %{id: id2}} = insert_concept("Electromagnetic Force", entity)

      assert [
               %Ontology.ConceptModel{id: ^id1},
               %Ontology.ConceptModel{id: ^id2}
             ] = from(Ontology.ConceptModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + error (different entities)", %{entity: entity} do
      user2 = Factories.insert!(:member)

      entity2 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user2.id}"
        })

      {:ok, _} = insert_concept("Gravitational Force", entity)
      {:error, changeset} = insert_concept("Gravitational Force", entity2)

      assert %{
               errors: [
                 phrase:
                   {"has already been taken",
                    [constraint: :unique, constraint_name: "ontology_concept_unique"]}
               ]
             } = changeset
    end

    test "insert + error (same entity)", %{entity: entity} do
      {:ok, _} = insert_concept("Gravitational Force", entity)
      {:error, changeset} = insert_concept("Gravitational Force", entity)

      assert %{
               errors: [
                 phrase:
                   {"has already been taken",
                    [constraint: :unique, constraint_name: "ontology_concept_unique"]}
               ]
             } = changeset
    end

    test "insert + error (same phrase and entity)", %{entity: entity} do
      {:ok, _} = insert_concept("Gravitational Force", entity)
      {:error, changeset} = insert_concept("Gravitational Force", entity)

      assert %{
               errors: [
                 phrase:
                   {"has already been taken",
                    [constraint: :unique, constraint_name: "ontology_concept_unique"]}
               ]
             } = changeset
    end
  end

  describe "insert_predicate/4" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      type = Factories.insert!(:ontology_concept, %{phrase: "is_a", entity: entity})
      object = Factories.insert!(:ontology_concept, %{phrase: "Force Of Nature", entity: entity})
      %{entity: entity, type: type, object: object}
    end

    test "insert", %{entity: entity, type: type, object: object} do
      subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
      assert {:ok, %Ontology.PredicateModel{}} = insert_predicate(subject, type, object, entity)
    end

    test "insert error (same subject and object)", %{entity: entity, type: type, object: object} do
      {:error, changeset} = insert_predicate(object, type, object, entity)

      assert [
               object_id:
                 {"is invalid",
                  [
                    constraint: :check,
                    constraint_name: "ontology_predicate_object_different_from_subject"
                  ]}
             ] = changeset.errors
    end

    test "insert + insert (different subjects)", %{entity: entity, type: type, object: object} do
      subject1 =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity})

      subject2 =
        Factories.insert!(:ontology_concept, %{phrase: "Electromagnetic Force", entity: entity})

      {:ok, %{id: id1}} = insert_predicate(subject1, type, object, entity)
      {:ok, %{id: id2}} = insert_predicate(subject2, type, object, entity)

      assert [
               %Ontology.PredicateModel{id: ^id1},
               %Ontology.PredicateModel{id: ^id2}
             ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + insert (different types)", %{entity: entity, type: type, object: object} do
      subject =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity})

      type2 = Factories.insert!(:ontology_concept, %{phrase: "related_to", entity: entity})
      {:ok, %{id: id1}} = insert_predicate(subject, type, object, entity)
      {:ok, %{id: id2}} = insert_predicate(subject, type2, object, entity)

      assert [
               %Ontology.PredicateModel{id: ^id1},
               %Ontology.PredicateModel{id: ^id2}
             ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + insert (different objects)", %{entity: entity, type: type, object: object} do
      subject =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity})

      object2 =
        Factories.insert!(:ontology_concept, %{phrase: "Natural Phenomenon", entity: entity})

      {:ok, %{id: id1}} = insert_predicate(subject, type, object, entity)
      {:ok, %{id: id2}} = insert_predicate(subject, type, object2, entity)

      assert [
               %Ontology.PredicateModel{id: ^id1},
               %Ontology.PredicateModel{id: ^id2}
             ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + insert (different entities)", %{entity: entity, type: type, object: object} do
      subject =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity})

      user2 = Factories.insert!(:member)

      entity2 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user2.id}"
        })

      {:ok, %{id: id1}} = insert_predicate(subject, type, object, entity)
      {:ok, %{id: id2}} = insert_predicate(subject, type, object, entity2)

      assert [
               %Ontology.PredicateModel{id: ^id1},
               %Ontology.PredicateModel{id: ^id2}
             ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + insert (different type_negated?)", %{
      entity: entity,
      type: type,
      object: object
    } do
      subject =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity})

      {:ok, %{id: id1}} = insert_predicate(subject, type, object, entity)
      {:ok, %{id: id2}} = insert_predicate(subject, type, object, entity, type_negated?: true)

      assert [
               %Ontology.PredicateModel{id: ^id1},
               %Ontology.PredicateModel{id: ^id2}
             ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

      assert id1 != id2
    end

    test "insert + update", %{entity: entity, type: type, object: object} do
      subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
      {:ok, %{id: id1}} = insert_predicate(subject, type, object, entity)
      {:error, changeset} = insert_predicate(subject, type, object, entity)

      assert [
               subject_id:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "ontology_predicate_unique"
                  ]}
             ] = changeset.errors

      assert [%Ontology.PredicateModel{id: ^id1}] =
               from(Ontology.PredicateModel) |> Core.Repo.all()
    end
  end

  describe "list concepts" do
    test "by entities" do
      user_1 = Factories.insert!(:member)
      user_2 = Factories.insert!(:member)

      entity_1 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user_1.id}"
        })

      entity_2 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user_2.id}"
        })

      %{id: concept_a_id} =
        Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", entity: entity_1})

      %{id: concept_b_id} =
        Factories.insert!(:ontology_concept, %{phrase: "Electromagnetic Force", entity: entity_1})

      _concept_c =
        Factories.insert!(:ontology_concept, %{phrase: "Weak Nuclear Force", entity: entity_2})

      assert [
               %Ontology.ConceptModel{id: ^concept_a_id},
               %Ontology.ConceptModel{id: ^concept_b_id}
             ] = list_concepts([entity_1], [:entity])
    end
  end
end
