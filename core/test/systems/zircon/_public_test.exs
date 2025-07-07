defmodule Systems.Zircon.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Annotation
  alias Systems.Zircon

  describe "insert_screening_tool_criterion/3" do
    test "inserts a criterion into the screening tool" do
      user = Factories.insert!(:member)
      %{id: tool_id} = tool = Factories.insert!(:zircon_screening_tool)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})

      Zircon.Public.insert_screening_tool_criterion(tool, dimension, user)

      assocs =
        Zircon.Screening.ToolAnnotationAssoc
        |> Repo.all()
        |> Repo.preload([:tool, annotation: [:type, references: [ontology_ref: [:concept]]]])

      assert [
               %{
                 tool: %{
                   id: ^tool_id
                 },
                 annotation: %{
                   statement: "Population unspecified",
                   type: %{
                     phrase: "Parameter"
                   },
                   references: [
                     %{
                       ontology_ref: %{
                         concept: %{phrase: "Population"}
                       }
                     }
                   ]
                 }
               }
             ] = assocs
    end

    test "handles duplicate criterion insertion gracefully" do
      user = Factories.insert!(:member)
      tool = Factories.insert!(:zircon_screening_tool)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})

      # Insert the same criterion twice
      {:ok, %{zircon_screening_tool_annotation_assoc: %{id: _id1}}} =
        Zircon.Public.insert_screening_tool_criterion(tool, dimension, user)

      {:error, :validate_criterion_does_not_exist, false, %{}} =
        Zircon.Public.insert_screening_tool_criterion(tool, dimension, user)
    end

    test "fails with invalid tool" do
      user = Factories.insert!(:member)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})
      invalid_tool = %{id: nil}

      assert_raise FunctionClauseError, fn ->
        Zircon.Public.insert_screening_tool_criterion(invalid_tool, dimension, user)
      end
    end

    test "fails with invalid dimension" do
      user = Factories.insert!(:member)
      tool = Factories.insert!(:zircon_screening_tool)
      invalid_dimension = %{id: nil}

      assert_raise FunctionClauseError, fn ->
        Zircon.Public.insert_screening_tool_criterion(tool, invalid_dimension, user)
      end
    end

    test "fails with invalid user" do
      tool = Factories.insert!(:zircon_screening_tool)
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})
      invalid_user = %{id: nil}

      assert_raise FunctionClauseError, fn ->
        Zircon.Public.insert_screening_tool_criterion(tool, dimension, invalid_user)
      end
    end

    test "creates correct annotation structure with different dimension types" do
      user = Factories.insert!(:member)
      tool = Factories.insert!(:zircon_screening_tool)
      intervention_dimension = Factories.insert!(:ontology_concept, %{phrase: "Intervention"})

      Zircon.Public.insert_screening_tool_criterion(tool, intervention_dimension, user)

      assocs =
        Zircon.Screening.ToolAnnotationAssoc
        |> Repo.all()
        |> Repo.preload([:tool, annotation: [:type, references: [ontology_ref: [:concept]]]])

      assert [
               %{
                 annotation: %{
                   statement: "Intervention unspecified",
                   type: %{phrase: "Parameter"},
                   references: [
                     %{
                       ontology_ref: %{
                         concept: %{phrase: "Intervention"}
                       }
                     }
                   ]
                 }
               }
             ] = assocs
    end

    test "handles multiple criteria for same tool" do
      user = Factories.insert!(:member)
      tool = Factories.insert!(:zircon_screening_tool)
      population_dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})
      outcome_dimension = Factories.insert!(:ontology_concept, %{phrase: "Outcome"})

      {:ok, %{zircon_screening_tool_annotation_assoc: %{id: id1}}} =
        Zircon.Public.insert_screening_tool_criterion(tool, population_dimension, user)

      {:ok, %{zircon_screening_tool_annotation_assoc: %{id: id2}}} =
        Zircon.Public.insert_screening_tool_criterion(tool, outcome_dimension, user)

      assert id1 != id2

      assocs =
        Zircon.Screening.ToolAnnotationAssoc
        |> Repo.all()
        |> Repo.preload([:tool, annotation: [:type, references: [ontology_ref: [:concept]]]])

      assert length(assocs) == 2

      phrases =
        assocs
        |> Enum.map(fn assoc ->
          assoc.annotation.references
          |> List.first()
          |> Map.get(:ontology_ref)
          |> Map.get(:concept)
          |> Map.get(:phrase)
        end)
        |> Enum.sort()

      assert phrases == ["Outcome", "Population"]
    end
  end

  describe "delete_screening_tool_criterion/2" do
    test "deletes a criterion from the screening tool" do
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})
      ontology_ref = Factories.insert!(:ontology_ref, %{concept: dimension})
      annotation_ref = Factories.insert!(:annotation_ref, %{ontology_ref: ontology_ref})
      annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Parameter"})

      %{id: annotation_id} =
        annotation =
        Factories.insert!(:annotation, %{
          statement: "Population unspecified",
          references: [annotation_ref],
          type: annotation_type
        })

      tool = Factories.insert!(:zircon_screening_tool, %{annotations: [annotation]})

      {:ok, result} = Zircon.Public.delete_screening_tool_criterion(tool, annotation)

      assert %{orphan_delete_criterion: %Annotation.Model{id: ^annotation_id}} = result
      assert Repo.all(Zircon.Screening.ToolAnnotationAssoc) == []
    end

    test "does not delete a criterion that is not orphaned" do
      dimension = Factories.insert!(:ontology_concept, %{phrase: "Population"})
      ontology_ref = Factories.insert!(:ontology_ref, %{concept: dimension})
      annotation1_ref = Factories.insert!(:annotation_ref, %{ontology_ref: ontology_ref})
      annotation1_type = Factories.insert!(:ontology_concept, %{phrase: "Parameter"})

      annotation1 =
        Factories.insert!(:annotation, %{
          statement: "Population unspecified",
          references: [annotation1_ref],
          type: annotation1_type
        })

      tool = Factories.insert!(:zircon_screening_tool, %{annotations: [annotation1]})

      # make sure the criterion is not orphaned by adding a reference to the annotation from another annotation
      annotation2_ref = Factories.insert!(:annotation_ref, %{annotation: annotation1})

      _annotation2 =
        Factories.insert!(:annotation, %{
          statement: "Population unspecified",
          references: [annotation2_ref]
        })

      {:ok, result} = Zircon.Public.delete_screening_tool_criterion(tool, annotation1)

      assert %{orphan_delete_criterion: "Criterion is not orphaned, skipping deletion"} = result
      assert Repo.all(Zircon.Screening.ToolAnnotationAssoc) == []
    end
  end
end
