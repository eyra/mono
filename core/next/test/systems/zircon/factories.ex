defmodule Systems.Zircon.Factories do
  alias Core.Factories

  def setup_ontology do
    context = %{
      subsumes: Factories.insert!(:ontology_concept, %{phrase: "Subsumes"}),
      definition: Factories.insert!(:ontology_concept, %{phrase: "Definition"}),
      parameter: Factories.insert!(:ontology_concept, %{phrase: "Parameter"})
    }

    research_dimension = Factories.insert!(:ontology_concept, %{phrase: "Research Dimension"})
    research_framework = Factories.insert!(:ontology_concept, %{phrase: "Research Framework"})

    # Dimensions
    dimension1 =
      insert_concept("Dimension 1", "Dimension 1 definition", research_dimension, context)

    dimension2 =
      insert_concept("Dimension 2", "Dimension 2 definition", research_dimension, context)

    dimension3 =
      insert_concept("Dimension 3", "Dimension 3 definition", research_dimension, context)

    dimension4 =
      insert_concept("Dimension 4", "Dimension 4 definition", research_dimension, context)

    # Frameworks
    framework1 =
      insert_concept("Framework 1", "Framework 1 definition", research_framework, context)

    framework2 =
      insert_concept("Framework 2", "Framework 2 definition", research_framework, context)

    framework3 =
      insert_concept("Framework 3", "Framework 3 definition", research_framework, context)

    Factories.insert!(:ontology_predicate, %{
      subject: dimension1,
      type: context.subsumes,
      object: framework1
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension2,
      type: context.subsumes,
      object: framework1
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension4,
      type: context.subsumes,
      object: framework1
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension1,
      type: context.subsumes,
      object: framework2
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension3,
      type: context.subsumes,
      object: framework2
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension2,
      type: context.subsumes,
      object: framework3
    })

    Factories.insert!(:ontology_predicate, %{
      subject: dimension3,
      type: context.subsumes,
      object: framework3
    })

    %{
      context: context,
      dimension1: dimension1,
      dimension2: dimension2,
      dimension3: dimension3,
      dimension4: dimension4,
      framework1: framework1,
      framework2: framework2,
      framework3: framework3,
      research_dimension: research_dimension,
      research_framework: research_framework
    }
  end

  def insert_concept(name, definition, category, context) do
    concept = Factories.insert!(:ontology_concept, %{phrase: name})

    concept_ref =
      Factories.insert!(:annotation_ref, %{
        ontology_ref: Factories.build(:ontology_ref, %{concept: concept})
      })

    Factories.insert!(:annotation, %{
      type: context.definition,
      statement: definition,
      references: [concept_ref]
    })

    Factories.insert!(:ontology_predicate, %{
      subject: concept,
      type: context.subsumes,
      object: category
    })

    concept
  end
end
