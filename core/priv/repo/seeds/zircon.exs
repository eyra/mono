defmodule Repo.Seeds.Zircon do
  @moduledoc """
  Zircon-specific concepts for systematic research methodology.

  This module defines the research frameworks and dimensions needed
  for Zircon's systematic review and literature analysis capabilities.
  Includes PICO, PICo, SPICE, SPIDER frameworks and related research concepts.
  """

  import Systems.Ontology.Public

  require Logger
  require Systems.Onyx.SeedBase
  import Systems.Onyx.SeedBase

  use Systems.Ontology.Constants

  alias Core.Authentication

  def run do
    # System actor / entity
    actor = Authentication.obtain_actor!(:system, "Zircon")
    entity = Authentication.obtain_entity!(actor)

    # Get the subsumes predicate from primitives (assumes primitives already loaded)
    subsumes = obtain_concept!(@subsumes, entity)

    # Research design elements
    %{
      category: _research_dimensions,
      members: [
        comparison,
        context,
        intervention,
        outcome,
        evaluation,
        perspective,
        phenomenon,
        population,
        sample,
        setting
      ]
    } =
      defconcepts(
        [
          comparison: "The control group or alternative intervention",
          context:
            "The broader environment or situational circumstances surrounding the research",
          intervention: "The treatment, exposure, or action studied",
          outcome: "The measurable result of the intervention",
          evaluation: "The process of assessing or measuring outcomes",
          perspective:
            "The stakeholder viewpoint or role from which the research is evaluated (e.g., patient, provider, payer)",
          phenomenon: "The qualitative research focus",
          population: "The target group that the research aims to understand or generalize to",
          sample:
            "The sampling strategy or approach used to select participants from the population",
          setting: "A specific geographic or organizational location"
        ],
        entity
      )
      |> defcategory(
        deftype(
          "Research Dimensions",
          "Group of concepts used to define research parameters",
          entity
        ),
        subsumes,
        entity
      )

    # Research design templates
    %{
      category: _research_frameworks,
      members: [pico, pic_o, spice, spider]
    } =
      defconcepts(
        [
          PICO:
            "A framework for clinical questions focusing on Population, Intervention, Comparison, and Outcome",
          PICo:
            "A qualitative research framework examining Population, phenomenon of Interest, and Context",
          SPICE:
            "A framework for service evaluation focusing on Setting, Perspective, Intervention, Comparison, and Evaluation",
          SPIDER:
            "A qualitative research framework examining Sample, Phenomenon of Interest, Design, Evaluation, and Research type"
        ],
        entity
      )
      |> defcategory(
        deftype("Research Frameworks", "Group of concepts used as research frameworks", entity),
        subsumes,
        entity
      )

    # Define framework compositions
    defcategory(
      [
        population,
        intervention,
        comparison,
        outcome
      ],
      pico,
      subsumes,
      entity
    )

    defcategory(
      [
        population,
        phenomenon,
        context
      ],
      pic_o,
      subsumes,
      entity
    )

    defcategory(
      [
        setting,
        perspective,
        intervention,
        comparison,
        evaluation
      ],
      spice,
      subsumes,
      entity
    )

    defcategory(
      [
        sample,
        phenomenon,
        evaluation
      ],
      spider,
      subsumes,
      entity
    )
  end
end

# Run the Zircon seeds
Repo.Seeds.Zircon.run()
