defmodule Systems.Annotation.Recipe.DefinitionTest do
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
      subject = Factories.insert!(:ontology_concept, %{phrase: "This Is A Subject"})

      %{author: author, subject: subject}
    end

    test "should return the inserted annotation", %{
      author: %{id: author_id} = author,
      subject: %{id: subject_id} = subject
    } do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a test",
        subject: subject,
        author: author
      }

      assert 0 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      assert {:ok, _annotation} = obtain(recipe)

      annotations =
        from(Annotation.Model)
        |> Repo.all()
        |> Repo.preload([:type, :author, references: [:ontology_ref]])

      assert [
               %Annotation.Model{
                 statement: "This is a test",
                 ai_generated?: false,
                 type: %Ontology.ConceptModel{
                   phrase: "Definition"
                 },
                 author: %Account.User{
                   id: ^author_id
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

    test "should return the existing annotation", %{author: author, subject: subject} do
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
          author: author,
          references: [annotation_ref]
        })

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()

      recipe = %Annotation.Recipe.Definition{
        definition: definition,
        subject: subject,
        author: author
      }

      assert {:ok, annotation_obtained} = Annotation.Recipe.obtain(recipe)

      assert annotation_obtained.id == annotation_existing.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return the same annotation with second obtain", %{
      author: author,
      subject: subject
    } do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a test",
        subject: subject,
        author: author
      }

      assert {:ok, annotation_1} = Annotation.Recipe.obtain(recipe)
      assert {:ok, annotation_2} = Annotation.Recipe.obtain(recipe)

      assert annotation_1.id == annotation_2.id

      assert 1 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "two different annotations should be created with two different statements", %{
      author: author,
      subject: subject
    } do
      recipe_1 = %Annotation.Recipe.Definition{
        definition: "This is a test",
        subject: subject,
        author: author
      }

      assert {:ok, annotation_1} = Annotation.Recipe.obtain(recipe_1)

      recipe_2 = %Annotation.Recipe.Definition{
        definition: "This is another test",
        subject: subject,
        author: author
      }

      assert {:ok, annotation_2} = Annotation.Recipe.obtain(recipe_2)

      assert annotation_1.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different concepts", %{
      author: author,
      subject: subject
    } do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        subject: subject,
        author: author
      }

      assert {:ok, annotation} = obtain(recipe)

      subject_2 = Factories.insert!(:ontology_concept, %{phrase: "This Is Another subject"})

      recipe_2 = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        subject: subject_2,
        author: author
      }

      assert {:ok, annotation_2} = obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should return two different annotations with two different authors", %{
      author: author,
      subject: subject
    } do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        subject: subject,
        author: author
      }

      assert {:ok, annotation} = obtain(recipe)

      author_2 = Factories.insert!(:member)

      recipe_2 = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        subject: subject,
        author: author_2
      }

      assert {:ok, annotation_2} = obtain(recipe_2)
      assert annotation.id != annotation_2.id

      assert 2 = from(Annotation.Model) |> Repo.all() |> Enum.count()
    end

    test "should raise an error if the definition is not provided", %{
      author: author,
      subject: subject
    } do
      recipe = %Annotation.Recipe.Definition{
        subject: subject,
        author: author
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end

    test "should raise an error if the subject is not provided", %{author: author} do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        author: author
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end

    test "should raise an error if the author is not provided", %{subject: subject} do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a definition",
        subject: subject
      }

      assert_raise Annotation.Recipe.MissingFieldError, fn ->
        obtain(recipe)
      end
    end
  end

  describe "query/3" do
    setup do
      author = Factories.insert!(:member)
      subject = Factories.insert!(:ontology_concept, %{phrase: "This Is A Subject"})
      annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Definition"})
      annotation_ref_type = Factories.insert!(:ontology_concept, %{phrase: "Subject"})
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
          author: author,
          references: [annotation_ref]
        })

      %{annotation: annotation}
    end

    test "should find the one annotation", %{annotation: %{id: annotation_id}} do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is a definition"
      }

      assert {:ok, query} = query(recipe)
      assert %{id: ^annotation_id} = query |> Repo.one()
    end

    test "should not find any annotation" do
      recipe = %Annotation.Recipe.Definition{
        definition: "This is another definition"
      }

      assert {:ok, query} = query(recipe)
      refute query |> Repo.exists?()
    end
  end
end
