defmodule Systems.Annotation.Pattern.DefinitionTest do
  use Core.DataCase

  import Ecto.Query, only: [from: 1]

  alias Core.Repo
  alias Core.Factories
  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  alias Systems.Annotation.Pattern.Definition

  describe "obtain/1" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      subject =
        Factories.insert!(:ontology_concept, %{phrase: "This Is A Subject", entity: entity})

      %{entity: entity, subject: subject}
    end

    test "should return the inserted annotation", %{
      entity: %{id: entity_id} = entity,
      subject: %{id: subject_id} = subject
    } do
      recipe = %Definition{
        definition: "This is a test",
        subject: subject,
        entity: entity
      }

      assert 0 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      assert {:ok, _annotation} = Annotation.Pattern.obtain(recipe)

      annotations =
        from(Annotation.Model)
        |> Repo.all()
        |> Repo.preload([:type, :entity, references: [:ontology_ref]])

      assert [
               %Annotation.Model{
                 statement: "This is a test",
                 type: %Ontology.ConceptModel{
                   phrase: "Definition"
                 },
                 entity: %Authentication.Entity{
                   id: ^entity_id
                 },
                 references: [
                   %Annotation.RefModel{
                     ontology_ref: %Ontology.RefModel{
                       concept_id: ^subject_id
                     }
                   }
                 ]
               }
             ] = annotations
    end

    test "should return the existing annotation", %{entity: entity, subject: subject} do
      annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Definition"})
      annotation_ref_type = Factories.insert!(:ontology_concept, %{phrase: "Subject"})

      ontology_ref = Factories.insert!(:ontology_ref, %{concept: subject})

      annotation_ref =
        Factories.insert!(:annotation_ref, %{
          type: annotation_ref_type,
          ontology_ref: ontology_ref
        })

      definition = "This is a test"

      annotation_existing =
        Factories.insert!(:annotation, %{
          statement: definition,
          type: annotation_type,
          entity: entity,
          references: [annotation_ref]
        })

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      recipe = %Definition{
        definition: definition,
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation_obtained} = Annotation.Pattern.obtain(recipe)

      assert annotation_obtained.id == annotation_existing.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return the same annotation with second obtain", %{
      entity: entity,
      subject: subject
    } do
      recipe = %Definition{
        definition: "This is a test",
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation_1} = Annotation.Pattern.obtain(recipe)

      assert {:ok, annotation_2} = Annotation.Pattern.obtain(recipe)

      assert annotation_1.id == annotation_2.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "two different annotations should be created with two different statements", %{
      entity: entity,
      subject: subject
    } do
      recipe_1 = %Definition{
        definition: "This is a test",
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation_1} = Annotation.Pattern.obtain(recipe_1)

      recipe_2 = %Definition{
        definition: "This is another test",
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation_2} = Annotation.Pattern.obtain(recipe_2)

      assert annotation_1.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different concepts", %{
      entity: entity,
      subject: subject
    } do
      recipe = %Definition{
        definition: "This is a definition",
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation} = Annotation.Pattern.obtain(recipe)

      subject_2 = Factories.insert!(:ontology_concept, %{phrase: "This Is Another subject"})

      recipe_2 = %Definition{
        definition: "This is a definition",
        subject: subject_2,
        entity: entity
      }

      assert {:ok, annotation_2} = Annotation.Pattern.obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different entities", %{
      entity: entity,
      subject: subject
    } do
      recipe = %Definition{
        definition: "This is a definition",
        subject: subject,
        entity: entity
      }

      assert {:ok, annotation} = Annotation.Pattern.obtain(recipe)

      user_2 = Factories.insert!(:member)

      entity_2 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user_2.id}"
        })

      recipe_2 = %Definition{
        definition: "This is a definition",
        subject: subject,
        entity: entity_2
      }

      assert {:ok, annotation_2} = Annotation.Pattern.obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should raise an error if the definition is not provided", %{
      entity: entity,
      subject: subject
    } do
      recipe = %Definition{
        subject: subject,
        entity: entity
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        Annotation.Pattern.obtain(recipe)
      end
    end

    test "should raise an error if the subject is not provided", %{entity: entity} do
      recipe = %Definition{
        definition: "This is a definition",
        entity: entity
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        Annotation.Pattern.obtain(recipe)
      end
    end

    test "should raise an error if the entity is not provided", %{subject: subject} do
      recipe = %Definition{
        definition: "This is a definition",
        subject: subject
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        Annotation.Pattern.obtain(recipe)
      end
    end
  end

  describe "query/3" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      subject =
        Factories.insert!(:ontology_concept, %{phrase: "This Is A Subject", entity: entity})

      annotation_type =
        Factories.insert!(:ontology_concept, %{phrase: "Definition", entity: entity})

      annotation_ref_type =
        Factories.insert!(:ontology_concept, %{phrase: "Subject", entity: entity})

      ontology_ref = Factories.insert!(:ontology_ref, %{concept: subject})

      annotation_ref =
        Factories.insert!(:annotation_ref, %{
          type: annotation_ref_type,
          ontology_ref: ontology_ref
        })

      annotation =
        Factories.insert!(:annotation, %{
          statement: "This is a definition",
          type: annotation_type,
          entity: entity,
          references: [annotation_ref]
        })

      %{annotation: annotation}
    end

    test "should find the one annotation", %{annotation: %{id: annotation_id}} do
      recipe = %Definition{
        definition: "This is a definition"
      }

      assert {:ok, query} = Annotation.Pattern.query(recipe)
      assert %{id: ^annotation_id} = query |> Repo.one()
    end

    test "should not find any annotation" do
      recipe = %Definition{
        definition: "This is another definition"
      }

      assert {:ok, query} = Annotation.Pattern.query(recipe)
      refute query |> Repo.exists?()
    end
  end
end
