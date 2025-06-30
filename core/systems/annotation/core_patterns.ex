defmodule Systems.Annotation.CorePatterns do
  @moduledoc """
  Core annotation patterns defined using the Pattern DSL.

  This module contains the fundamental annotation patterns used throughout
  the platform for human-AI knowledge collaboration.
  """

  use Systems.Annotation.PatternDSL

  defpattern "Feedback Pattern" do
    version("1.0.0")
    description("Generic AI feedback on human statements for knowledge refinement")

    statement do
      template("AI Analysis: {analysis_content}")
      min_length(20)
      max_length(2000)
    end

    optional_reference "analyzes" do
      ref_description("The annotation being analyzed by the AI")
      target_types(["annotation"])
      cardinality(:exactly_one)
    end

    optional_reference "extracts" do
      ref_description("Concepts extracted from the analyzed statement")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "identifies" do
      ref_description("Predicates identified in the analyzed statement")
      target_types(["predicate"])
      cardinality(:zero_or_more)
    end

    metadata(category: "ai_interaction", priority: "high")
  end

  defpattern "Response Pattern" do
    version("1.0.0")
    description("Human response to AI feedback in the knowledge refinement loop")

    statement do
      template("{response_content}")
      min_length(5)
      max_length(1000)
    end

    required_reference "responds_to" do
      ref_description("The AI feedback annotation being responded to")
      target_types(["annotation"])
      cardinality(:exactly_one)
    end

    optional_reference "validates" do
      ref_description("Concepts that the human validates as correct")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "rejects" do
      ref_description("Concepts that the human rejects as incorrect")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "refines" do
      ref_description("Concepts that the human wants to refine or modify")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    metadata(category: "human_interaction", priority: "high")
  end

  defpattern "Statement Pattern" do
    version("1.0.0")
    description("Original human statement for AI analysis and knowledge extraction")

    statement do
      template("{statement_content}")
      min_length(10)
      max_length(5000)
    end

    optional_reference "about" do
      ref_description("Main concepts or topics the statement discusses")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "context" do
      ref_description("Contextual information or domain knowledge")
      target_types(["annotation", "concept"])
      cardinality(:zero_or_more)
    end

    metadata(category: "human_input", priority: "medium")
  end

  defpattern "Definition Pattern" do
    version("1.0.0")
    description("Formal definitions of concepts for knowledge base building")

    statement do
      template("{concept_name}: {definition_content}")
      min_length(15)
      max_length(1000)
      required_fields(["concept_name", "definition_content"])
    end

    required_reference "defines" do
      ref_description("The concept being defined")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    optional_reference "relates_to" do
      ref_description("Related concepts mentioned in the definition")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "source" do
      ref_description("Source annotation or document for this definition")
      target_types(["annotation"])
      cardinality(:zero_or_more)
    end

    metadata(category: "knowledge_structure", priority: "high")
  end

  defpattern "Validation Pattern" do
    version("1.0.0")
    description("Human validation of AI-discovered knowledge structures")

    statement do
      template("Validation: {validation_decision} - {reasoning}")
      min_length(20)
      max_length(1000)
      required_fields(["validation_decision", "reasoning"])
    end

    required_reference "validates" do
      ref_description("The knowledge element being validated")
      target_types(["concept", "predicate", "annotation"])
      cardinality(:exactly_one)
    end

    optional_reference "supports" do
      ref_description("Supporting evidence or reasoning")
      target_types(["annotation", "concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "contradicts" do
      ref_description("Contradictory evidence or counter-arguments")
      target_types(["annotation", "concept"])
      cardinality(:zero_or_more)
    end

    metadata(category: "validation", priority: "critical")
  end

  defpattern "Research Finding Pattern" do
    version("1.0.0")
    description("Structured research findings from literature review or studies")

    statement do
      template("Finding: {finding_content} (Study: {study_info})")
      min_length(30)
      max_length(2000)
      required_fields(["finding_content", "study_info"])
    end

    required_reference "methodology" do
      ref_description("Research methodology or approach used")
      target_types(["concept"])
      cardinality(:one_or_more)
    end

    optional_reference "measures" do
      ref_description("Variables or metrics measured in the study")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "population" do
      ref_description("Study population or sample characteristics")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "conclusions" do
      ref_description("Main conclusions or implications")
      target_types(["predicate"])
      cardinality(:zero_or_more)
    end

    metadata(category: "research", priority: "high", domain: "academic")
  end

  defpattern "Hypothesis Pattern" do
    version("1.0.0")
    description("Research hypotheses and theoretical propositions")

    statement do
      template("Hypothesis: {hypothesis_content}")
      min_length(20)
      max_length(1000)
      required_fields(["hypothesis_content"])
    end

    required_reference "proposes" do
      ref_description("The relationship or effect being proposed")
      target_types(["predicate"])
      cardinality(:one_or_more)
    end

    optional_reference "based_on" do
      ref_description("Theoretical foundation or prior research")
      target_types(["annotation", "concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "testable_via" do
      ref_description("Potential methods for testing the hypothesis")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    metadata(category: "research", priority: "medium", domain: "academic")
  end
end
