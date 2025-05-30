defmodule Ontology.PublicTest do
    use Core.DataCase

    alias Core.Repo
    import Systems.Ontology.Public
    alias Systems.Ontology

    describe "insert_concept/3" do
        setup do
            author = Factories.insert!(:member)
            %{author: author}
        end

        test "insert", %{author: author} do
            assert {:ok, %Ontology.ConceptModel{}} = insert_concept("Gravitational Force", author)
        end

        test "insert + insert (different phrases)", %{author: author} do
            {:ok, %{id: id1}} = insert_concept("Gravitational Force", author)
            {:ok, %{id: id2}} = insert_concept("Electromagnetic Force", author)

            assert [
                %Ontology.ConceptModel{id: ^id1},
                %Ontology.ConceptModel{id: ^id2}
            ] = from(Ontology.ConceptModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + error (different authors)", %{author: author} do

            author2 = Factories.insert!(:member)

            {:ok, _} = insert_concept("Gravitational Force", author)
            {:error, changeset} = insert_concept("Gravitational Force", author2)

            assert %{
                errors: [
                    phrase: {"has already been taken",
                        [constraint: :unique, constraint_name: "ontology_concept_unique"]}
                ]
            } = changeset
        end

        test "insert + error (same author)", %{author: author} do
            {:ok, _} = insert_concept("Gravitational Force", author)
            {:error, changeset} = insert_concept("Gravitational Force", author)

            assert %{
                errors: [
                    phrase: {"has already been taken",
                        [constraint: :unique, constraint_name: "ontology_concept_unique"]}
                ]
            } = changeset
        end

        test "insert + error (same phrase and author)", %{author: author} do
            {:ok, _} = insert_concept("Gravitational Force", author)
            {:error, changeset} = insert_concept("Gravitational Force", author)

            assert %{
                errors: [
                    phrase: {"has already been taken",
                        [constraint: :unique, constraint_name: "ontology_concept_unique"]}
                ]
            } = changeset
        end
    end

    describe "insert_predicate/4" do
        setup do
            author = Factories.insert!(:member)
            type = Factories.insert!(:ontology_concept, %{phrase: "is_a"})
            object = Factories.insert!(:ontology_concept, %{phrase: "Force Of Nature"})
            %{author: author, type: type, object: object}
        end

        test "insert", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            assert {:ok, %Ontology.PredicateModel{}} = insert_predicate(subject, type, object, author)
        end

        test "insert error (same subject and object)", %{author: author, type: type, object: object} do
            {:error, changeset} = insert_predicate(object, type, object, author)
            assert [
                object_id: {"is invalid",
                 [
                   constraint: :check,
                   constraint_name: "ontology_predicate_object_different_from_subject"
                 ]}
              ] = changeset.errors
        end

        test "insert + insert (different subjects)", %{author: author, type: type, object: object} do
            subject1 = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            subject2 = Factories.insert!(:ontology_concept, %{phrase: "Electromagnetic Force"})
            {:ok, %{id: id1}} = insert_predicate(subject1, type, object, author)
            {:ok, %{id: id2}} = insert_predicate(subject2, type, object, author)

            assert [
                %Ontology.PredicateModel{id: ^id1},
                %Ontology.PredicateModel{id: ^id2}
            ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + insert (different types)", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            type2 = Factories.insert!(:ontology_concept, %{phrase: "related_to"})
            {:ok, %{id: id1}} = insert_predicate(subject, type, object, author)
            {:ok, %{id: id2}} = insert_predicate(subject, type2, object, author)

            assert [
                %Ontology.PredicateModel{id: ^id1},
                %Ontology.PredicateModel{id: ^id2}
            ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + insert (different objects)", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            object2 = Factories.insert!(:ontology_concept, %{phrase: "Natural Phenomenon"})
            {:ok, %{id: id1}} = insert_predicate(subject, type, object, author)
            {:ok, %{id: id2}} = insert_predicate(subject, type, object2, author)

            assert [
                %Ontology.PredicateModel{id: ^id1},
                %Ontology.PredicateModel{id: ^id2}
            ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + insert (different authors)", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            author2 = Factories.insert!(:member)
            {:ok, %{id: id1}} = insert_predicate(subject, type, object, author)
            {:ok, %{id: id2}} = insert_predicate(subject, type, object, author2)

            assert [
                %Ontology.PredicateModel{id: ^id1},
                %Ontology.PredicateModel{id: ^id2}
            ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + insert (different type_negated?)", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            {:ok, %{id: id1}} = insert_predicate(subject, type, object, author)
            {:ok, %{id: id2}} = insert_predicate(subject, type, object, author, type_negated?: true)

            assert [
                %Ontology.PredicateModel{id: ^id1},
                %Ontology.PredicateModel{id: ^id2}
            ] = from(Ontology.PredicateModel, order_by: :id) |> Repo.all()

            assert id1 != id2
        end

        test "insert + update", %{author: author, type: type, object: object} do
            subject = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force"})
            {:ok, %{id: id1}} = insert_predicate(subject, type, object, author)
            {:error, changeset} = insert_predicate(subject, type, object, author)

            assert [
                subject_id: {"has already been taken",
                 [
                   constraint: :unique,
                   constraint_name: "ontology_predicate_unique_predicate"
                 ]}
              ] = changeset.errors

            assert [%Ontology.PredicateModel{id: ^id1}] = from(Ontology.PredicateModel) |> Core.Repo.all()
        end

    end

    describe "list concepts" do
        test "by author" do
            author_1 = Factories.insert!(:member)
            author_2 = Factories.insert!(:member)

            %{id: concept_a_id} = Factories.insert!(:ontology_concept, %{phrase: "Gravitational Force", author: author_1})
            %{id: concept_b_id} = Factories.insert!(:ontology_concept, %{phrase: "Electromagnetic Force", author: author_1})
            _concept_c = Factories.insert!(:ontology_concept, %{phrase: "Weak Nuclear Force", author: author_2})

            assert [
                %Ontology.ConceptModel{id: ^concept_a_id},
                %Ontology.ConceptModel{id: ^concept_b_id},
            ] = list_concepts_by_author(author_1)
        end
    end
end