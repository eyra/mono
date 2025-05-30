defmodule Systems.Onyx.Seeds do
  @moduledoc """
  A module for creating the initial Ontology concepts and predicates and Annotations.
  Values reserved for internal (technical) use have the "double underscore notation" or "dunder naming"
  to differentiate them from user-defined values.
  """

  import Systems.Annotation.Public
  import Systems.Ontology.Public

  def run do
    # System user
    user = SystemSignIn.setup_user(:onyx)

    # Fundamental concepts
    {:ok, subsumes} = insert_concept("Subsumes", user)
    {:ok, definition} = insert_concept("Definition", user)
    {:ok, subject} = insert_concept("Subject", user)

    defconcept = fn(phrase, text) ->
      {:ok, concept} = insert_concept(phrase, user)
      insert_annotation(definition, text, user, subject, concept)
      concept
    end

    defconcepts = fn(keyword) ->
      Enum.map(keyword, fn({atom, text}) ->
        atom
        |> Atom.to_string()
        |> String.upcase()
        |> defconcept.(text)
      end)
    end

    defgroup = fn(objects, subject) ->
      Enum.each(objects, fn(object) ->
        insert_predicate(subject, subsumes, object, user)
      end)
      objects
    end

    deftype = fn(phrase, text) ->
      defconcept.(phrase, text)
    end

    # Predicate types

    defconcepts.([
      subsumes: "Hierarchical relationship between concepts",
      composes: "A relationship between a parent and child concept",
      compares: "A relationship between two concepts that compare",
      influences: "A relationship between a cause and effect",
      transforms: "A relationship between a transformation",
      interacts: "A relationship between two concepts that interact"
    ])
    |> defgroup.(deftype.("__predicate_type__", "A relationship between two concepts"))

    # Annotation types

    defconcepts.([
      description: "A formal, precise, and unambiguous definition of a concept",
      reference: "An external source that provides additional information about a concept",
      comment: "A subjective public expression",
      note: "A message to self",
      proposition: "A statement that can be either true or false and is subject to logical evaluation",
      prediction: "A statement about a future event or outcome based on current knowledge or evidence",
      hypothesis: "A testable proposition or prediction",
      claim: "An assertion that requires evidence/support",
      evidence: "Supporting data or observations",
      conclusion: "A reasoned judgment drawn from evidence",
      assumption: "An underlying premise taken as given"
    ])
    |> defgroup.(deftype.("__annotation_type__", "A formal, precise, and unambiguous definition of a concept"))

    # Annotation reference types

    defconcepts.([
      source: "An external source that provides additional information about a concept",
      example: "A concrete instance or illustration of the annotation",
      context: "The environmental or situational framework for the annotation",
      related: "An associated reference that provides additional understanding"
    ])
    |> defgroup.(deftype.("__annotation_ref_type__", "An external reference that provides additional information about an annotation"))

    # Research design elements

    [population, intervention, comparison, outcome, phenomenon, context, setting] = [
      population: "The group, subjects or sample being studied",
      intervention: "The treatment, exposure, or action studied",
      comparison: "The control group or alternative intervention",
      outcome: "The measurable result of the intervention (also called Evaluation)",
      phenomenon: "The qualitative research focus",
      context: "The broader environment or situational circumstances surrounding the research",
      setting: "A specific geographic or organizational location"
    ]
    |> defconcepts.()
    |> defgroup.(deftype.("__research_design_element__", "A component of a research design"))

    # Research design templates

    [p_i_c_o, p_i_co, s_p_i_c_e, s_pi_d_e_r] = [
      p_i_c_o: "A framework for clinical questions focusing on Population, Intervention, Comparison, and Outcome",
      p_i_co: "A qualitative research framework examining Population, phenomenon of Interest, and Context",
      s_p_i_c_e: "A framework for service evaluation focusing on Setting, Perspective, Intervention, Comparison, and Evaluation",
      s_pi_d_e_r: "A qualitative research framework examining Sample, Phenomenon of Interest, Design, Evaluation, and Research type"
    ]
    |> defconcepts.()
    |> defgroup.(deftype.("__research_design_template__", "A template for a research design"))

   defgroup.([
      population,
      intervention,
      comparison,
      outcome
    ], p_i_c_o)

    defgroup.([
      setting,
      population,
      intervention,
      comparison,
      outcome # Evaluation
    ])

    defgroup.([
      population, # Sample
      phenomenon,
      outcome # Evaluation
    ], s_pi_d_e_r)
  end
end

# Run the seeds
Systems.Onyx.Seeds.run()