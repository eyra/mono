defmodule Repo.Seeds.OnyxPrimitives do
  @moduledoc """
  Core primitive concepts for the Onyx knowledge system.

  This module defines the fundamental primitives that form the foundation
  of all knowledge representation:
  - subsumes (the base relational primitive)
  - definition (the meaning primitive)
  - subject (the entity primitive)

  Plus the essential predicate and annotation types that enable
  basic knowledge operations.
  """

  use Systems.Ontology.Constants

  require Logger
  require Systems.Onyx.SeedBase
  import Systems.Onyx.SeedBase
  import Systems.Ontology.Public

  alias Core.Authentication

  def run do
    # System actor / entity
    actor = Authentication.obtain_actor!(:system, "Onyx")
    entity = Authentication.obtain_entity!(actor)

    # Most basic concepts
    subsumes = obtain_concept!(@subsumes, entity)
    _definition = obtain_concept!(@definition, entity)
    _subject = obtain_concept!(@subject, entity)

    # Predicate primitives
    defconcepts(
      [
        subsumes:
          "A hierarchical predicate type where the subject is a specific instance or subtype of the object",
        composes:
          "A compositional predicate type where the subject is a component or part of the object",
        compares:
          "A relational predicate type between two concepts that are equivalent or similar",
        influences: "A causal predicate type where the subject affects or impacts the object",
        transforms:
          "A temporal predicate type where the subject changes or converts into the object",
        interacts:
          "A predicate type where the subject and object have mutual effects on each other",
        locates:
          "A spatial predicate type where the subject exists at, near, or within the object"
      ],
      entity
    )
    |> defcategory(
      deftype("Predicate Types", "Group of concepts used as predicate types", entity),
      subsumes,
      entity
    )

    # Annotation primitives
    defconcepts(
      [
        definition: "A formal, precise, and unambiguous definition of a concept",
        reference: "An external source that provides additional information about a concept",
        comment: "A subjective public expression",
        note: "A message to self",
        proposition:
          "A statement that can be either true or false and is subject to logical evaluation",
        prediction:
          "A statement about a future event or outcome based on current knowledge or evidence",
        hypothesis: "A testable proposition or prediction",
        claim: "An assertion that requires evidence/support",
        evidence: "Supporting data or observations",
        conclusion: "A reasoned judgment drawn from evidence",
        assumption: "An underlying premise taken as given"
      ],
      entity
    )
    |> defcategory(
      deftype("Annotation Types", "Group of concepts used as annotation types", entity),
      subsumes,
      entity
    )

    # Annotation reference primitives
    defconcepts(
      [
        subject: "The main subject of an annotation",
        example: "A concrete instance or illustration of the annotation",
        context: "The environmental or situational framework for the annotation",
        related: "An associated reference that provides additional understanding"
      ],
      entity
    )
    |> defcategory(
      deftype(
        "Annotation Reference Types",
        "Group of concepts used as annotation reference types",
        entity
      ),
      subsumes,
      entity
    )
  end
end

# Run the primitives
Repo.Seeds.OnyxPrimitives.run()
