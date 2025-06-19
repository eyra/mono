defmodule Systems.Annotation.Recipe.ParameterTest do
  use Core.DataCase

  import Ecto.Query, only: [from: 1]
  import Systems.Annotation.Recipe

  alias Core.Repo
  alias Core.Factories
  alias Systems.Account
  alias Systems.Annotation
  alias Systems.Ontology

  describe "obtain/1" do
    setup do
      author = Factories.insert!(:member)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "This Is A Dimension"})

      %{author: author, dimension: dimension}
    end

    test "should return the inserted annotation", %{
      author: %{id: author_id} = author,
      dimension: %{id: dimension_id} = dimension
    } do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author
      }

      assert 0 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      assert {:ok, _annotation} = obtain(recipe)

      annotations =
        from(Annotation.Model)
        |> Repo.all()
        |> Repo.preload([:type, :author, references: [ontology_ref: [:concept]]])

      assert [
               %Annotation.Model{
                 statement: "This is a parameter",
                 ai_generated?: false,
                 type: %Ontology.ConceptModel{
                   phrase: "Parameter"
                 },
                 author: %Account.User{
                   id: ^author_id
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

    test "should return the existing annotation", %{author: author, dimension: dimension} do
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
          author: author,
          references: [annotation_ref]
        })

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      recipe = %Annotation.Recipe.Parameter{
        parameter: parameter,
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation_obtained} = Annotation.Recipe.obtain(recipe)

      assert annotation_obtained.id == annotation_existing.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return the same annotation with second obtain", %{
      author: author,
      dimension: dimension
    } do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation_1} = Annotation.Recipe.obtain(recipe)
      assert {:ok, annotation_2} = Annotation.Recipe.obtain(recipe)

      assert annotation_1.id == annotation_2.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "two different annotations should be created with two different parameters", %{
      author: author,
      dimension: dimension
    } do
      recipe_1 = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation_1} = Annotation.Recipe.obtain(recipe_1)

      recipe_2 = %Annotation.Recipe.Parameter{
        parameter: "This is another parameter",
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation_2} = Annotation.Recipe.obtain(recipe_2)

      assert annotation_1.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different dimensions", %{
      author: author,
      dimension: dimension
    } do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation} = obtain(recipe)

      dimension_2 = Factories.insert!(:ontology_concept, %{phrase: "This Is Another Dimension"})

      recipe_2 = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension_2,
        author: author
      }

      assert {:ok, annotation_2} = obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different authors", %{
      author: author,
      dimension: dimension
    } do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author
      }

      assert {:ok, annotation} = obtain(recipe)

      author_2 = Factories.insert!(:member)

      recipe_2 = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension,
        author: author_2
      }

      assert {:ok, annotation_2} = obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should raise an error if the parameter is not provided", %{
      author: author,
      dimension: dimension
    } do
      recipe = %Annotation.Recipe.Parameter{
        dimension: dimension,
        author: author
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end

    test "should raise an error if the dimension is not provided", %{author: author} do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        author: author
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end

    test "should raise an error if the author is not provided", %{dimension: dimension} do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter",
        dimension: dimension
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end
  end

  describe "query/3" do
    setup do
      author = Factories.insert!(:member)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "This Is A Dimension"})
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
          author: author,
          references: [annotation_ref]
        })

      %{annotation: annotation}
    end

    test "should find the one annotation", %{annotation: %{id: annotation_id}} do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is a parameter"
      }

      assert {:ok, query} = query(recipe)
      assert %{id: ^annotation_id} = query |> Repo.one()
    end

    test "should not find any annotation" do
      recipe = %Annotation.Recipe.Parameter{
        parameter: "This is another parameter"
      }

      assert {:ok, query} = query(recipe)
      refute query |> Repo.exists?()
    end
  end
end
