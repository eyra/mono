defmodule Systems.Onyx.Seeds do
  @moduledoc """
  A module for creating the initial Ontology concepts and predicates and Annotations.
  Values reserved for internal (technical) use have the "double underscore notation" or "dunder naming"
  to differentiate them from user-defined dbgs.
  """

  import Systems.Annotation.Public
  import Systems.Ontology.Public

  require Logger

  use Systems.Ontology.Constants
  use Systems.Annotation.Constants

  def run do
    # System user
    user = SystemSignIn.setup_user(:onyx)

    # Fundamental ontology concepts
    %{subsumes: subsumes} = setup_ontology_fundamentals(user)

    # Fundamental annotation concepts
    %{definition: definition, subject: subject} = setup_annotation_fundamentals(user)

    defconcept = fn phrase, text ->
      concept = obtain_concept!(phrase, user)

      {:ok, _annotation} =
        %Annotation.Recipe.Definition{
          statement: text,
          concept: concept,
          author: user
        }
        |> Annotation.Recipe.Definition.obtain()

      concept
    end

    defconcepts = fn keyword ->
      Enum.map(keyword, fn {atom, text} ->
        atom
        |> Atom.to_string()
        |> String.capitalize()
        |> defconcept.(text)
      end)
    end

    defgroup = fn objects, subject ->
      Enum.each(objects, fn object ->
        obtain_predicate(subject, subsumes, object, user)
      end)

      objects
    end

    deftype = fn phrase, text ->
      defconcept.(phrase, text)
    end

    # Predicate types

    defconcepts.(
      composes: "A relationship between a parent and child concept",
      compares: "A relationship between two concepts that compare",
      influences: "A relationship between a cause and effect",
      transforms: "A relationship between a transformation",
      interacts: "A relationship between two concepts that interact"
    )
    |> defgroup.(deftype.("__predicate_type__", "A relationship between two concepts"))

    # Annotation types

    defconcepts.(
      description: "A formal, precise, and unambiguous definition of a concept",
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
    )
    |> defgroup.(deftype.("__annotation_type__", "Annotation type"))

    # Annotation reference types

    defconcepts.(
      subject: "The main subject of an annotation",
      example: "A concrete instance or illustration of the annotation",
      context: "The environmental or situational framework for the annotation",
      related: "An associated reference that provides additional understanding"
    )
    |> defgroup.(deftype.("__annotation_ref_type__", "Annotation reference type"))

    # Research design elements

    [
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
    ] =
      [
        comparison: "The control group or alternative intervention",
        context: "The broader environment or situational circumstances surrounding the research",
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
      ]
      |> defconcepts.()
      |> defgroup.(deftype.("__research_design_element__", "A component of a research design"))

    # Research design templates

    [p_i_c_o, p_i_co, s_p_i_c_e, s_pi_d_e_r] =
      [
        p_i_c_o:
          "A framework for clinical questions focusing on Population, Intervention, Comparison, and Outcome",
        p_i_co:
          "A qualitative research framework examining Population, phenomenon of Interest, and Context",
        s_p_i_c_e:
          "A framework for service evaluation focusing on Setting, Perspective, Intervention, Comparison, and Evaluation",
        s_pi_d_e_r:
          "A qualitative research framework examining Sample, Phenomenon of Interest, Design, Evaluation, and Research type"
      ]
      |> defconcepts.()
      |> defgroup.(deftype.("__research_design_template__", "A template for a research design"))

    defgroup.(
      [
        population,
        intervention,
        comparison,
        outcome
      ],
      p_i_c_o
    )

    defgroup.(
      [
        population,
        phenomenon,
        context
      ],
      p_i_co
    )

    defgroup.(
      [
        setting,
        perspective,
        intervention,
        comparison,
        evaluation
      ],
      s_p_i_c_e
    )

    defgroup.(
      [
        sample,
        phenomenon,
        evaluation
      ],
      s_pi_d_e_r
    )
  end

  defp setup_ontology_fundamentals(user) do
    %{
      subsumes: obtain_concept!(@subsumes, user)
    }
  end

  defp setup_annotation_fundamentals(user) do
    %{
      definition: obtain_concept!(@definition, user),
      subject: obtain_concept!(@subject, user)
    }
  end

  defp insert_annotation(definition, text, user, subject, concept) do
    case insert_annotation(definition, text, user, subject, concept) do
      {:ok, _} ->
        Logger.debug("Insert annotation successful: #{phrase} '#{text}'")

      {:error, error} ->
        Logger.debug("[Error] Insert annotation failed: #{phrase} '#{text}'")

      {:error, :annotation,
       %{
         errors: [
           statement:
             {"has already been taken",
              [constraint: :unique, constraint_name: "annotation_unique"]}
         ]
       }, _} ->
        Logger.debug("[Error] Annotation has already been taken: #{phrase} '#{text}'")
    end
  end
end

# Run the seeds
Systems.Onyx.Seeds.run()
