defmodule Systems.Annotation.Pattern.ParameterTest do
  use Core.DataCase

  import Ecto.Query, only: [from: 1]
  import Systems.Annotation.Pattern

  alias Core.Repo
  alias Core.Factories
  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  describe "obtain/1" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      dimension =
        Factories.insert!(:ontology_concept, %{phrase: "This Is A Dimension", entity: entity})

      %{entity: entity, dimension: dimension}
    end

    test "should return the inserted annotation", %{
      entity: %{id: entity_id} = entity,
      dimension: %{id: dimension_id} = dimension
    } do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity
      }

      assert 0 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      assert {:ok, _annotation} = obtain(pattern)

      annotations =
        from(Annotation.Model)
        |> Repo.all()
        |> Repo.preload([:type, :entity, references: [ontology_ref: [:concept]]])

      assert [
               %Annotation.Model{
                 statement: "This is a parameter",
                 type: %Ontology.ConceptModel{
                   phrase: "Parameter"
                 },
                 entity: %Authentication.Entity{
                   id: ^entity_id
                 },
                 references: [
                   %Annotation.RefModel{
                     ontology_ref: %Ontology.RefModel{
                       concept: %Ontology.ConceptModel{
                         id: ^dimension_id,
                         phrase: "This Is A Dimension"
                       }
                     }
                   }
                 ]
               }
             ] = annotations
    end

    test "should return the existing annotation", %{entity: entity, dimension: dimension} do
      annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Parameter"})
      annotation_ref_type = Factories.insert!(:ontology_concept, %{phrase: "Dimension"})

      ontology_ref = Factories.insert!(:ontology_ref, %{concept: dimension})

      annotation_ref =
        Factories.insert!(:annotation_ref, %{
          type: annotation_ref_type,
          ontology_ref: ontology_ref
        })

      parameter = "This is a parameter"

      annotation_existing =
        Factories.insert!(:annotation, %{
          statement: parameter,
          type: annotation_type,
          entity: entity,
          references: [annotation_ref]
        })

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      pattern = %Annotation.Pattern.Parameter{
        parameter: parameter,
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation_obtained} = Annotation.Pattern.obtain(pattern)

      assert annotation_obtained.id == annotation_existing.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return the same annotation with second obtain", %{
      entity: entity,
      dimension: dimension
    } do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation_1} = Annotation.Pattern.obtain(pattern)
      assert {:ok, annotation_2} = Annotation.Pattern.obtain(pattern)

      assert annotation_1.id == annotation_2.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "two different annotations should be created with two different parameters", %{
      entity: entity,
      dimension: dimension
    } do
      pattern_1 = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation_1} = Annotation.Pattern.obtain(pattern_1)

      pattern_2 = %Annotation.Pattern.Parameter{
        parameter: "This is another parameter",
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation_2} = Annotation.Pattern.obtain(pattern_2)

      assert annotation_1.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different dimensions", %{
      entity: entity,
      dimension: dimension
    } do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation} = obtain(pattern)

      dimension_2 =
        Factories.insert!(:ontology_concept, %{
          phrase: "This Is Another Dimension",
          entity: entity
        })

      pattern_2 = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension_2,
        entity: entity
      }

      assert {:ok, annotation_2} = obtain(pattern_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different entities", %{
      entity: entity,
      dimension: dimension
    } do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity
      }

      assert {:ok, annotation} = obtain(pattern)

      user_2 = Factories.insert!(:member)

      entity_2 =
        Factories.insert!(:authentication_entity, %{
          identifier: "Systems.Account.User:#{user_2.id}"
        })

      pattern_2 = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        entity: entity_2
      }

      assert {:ok, annotation_2} = obtain(pattern_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should raise an error if the parameter is not provided", %{
      entity: entity,
      dimension: dimension
    } do
      pattern = %Annotation.Pattern.Parameter{
        dimension: dimension,
        entity: entity
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        obtain(pattern)
      end
    end

    test "should raise an error if the dimension is not provided", %{entity: entity} do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        entity: entity
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        obtain(pattern)
      end
    end

    test "should raise an error if the entity is not provided", %{dimension: dimension} do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter",
        dimension: dimension
      }

      assert_raise Annotation.Pattern.MissingFieldError, fn ->
        obtain(pattern)
      end
    end
  end

  describe "query/3" do
    setup do
      user = Factories.insert!(:member)

      entity =
        Factories.insert!(:authentication_entity, %{identifier: "Systems.Account.User:#{user.id}"})

      dimension =
        Factories.insert!(:ontology_concept, %{phrase: "This Is A Dimension", entity: entity})

      annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Parameter"})
      annotation_ref_type = Factories.insert!(:ontology_concept, %{phrase: "Dimension"})
      ontology_ref = Factories.insert!(:ontology_ref, %{concept: dimension})

      annotation_ref =
        Factories.insert!(:annotation_ref, %{
          type: annotation_ref_type,
          ontology_ref: ontology_ref
        })

      annotation =
        Factories.insert!(:annotation, %{
          statement: "This is a parameter",
          type: annotation_type,
          entity: entity,
          references: [annotation_ref]
        })

      %{annotation: annotation}
    end

    test "should find the one annotation", %{annotation: %{id: annotation_id}} do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is a parameter"
      }

      assert {:ok, query} = query(pattern)
      assert %{id: ^annotation_id} = query |> Repo.one()
    end

    test "should not find any annotation" do
      pattern = %Annotation.Pattern.Parameter{
        parameter: "This is another parameter"
      }

      assert {:ok, query} = query(pattern)
      refute query |> Repo.exists?()
    end
  end
end
