defmodule Systems.Annotation.ExampleCustomPatterns do
  @moduledoc """
  Example of how to define custom annotation patterns using the Pattern DSL.

  This demonstrates the flexibility and ease of extending the pattern system
  for domain-specific knowledge structures.
  """

  use Systems.Annotation.PatternDSL

  defpattern "GDPR Compliance Pattern" do
    version("1.0.0")
    description("Structured annotation for GDPR compliance requirements and assessments")

    statement do
      template("GDPR Assessment: {requirement} - Status: {compliance_status} - {details}")
      min_length(30)
      max_length(1500)
      required_fields(["requirement", "compliance_status", "details"])
    end

    required_reference "applies_to" do
      ref_description("The system or process being assessed for GDPR compliance")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    optional_reference "legal_basis" do
      ref_description("Legal basis for data processing under GDPR")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "data_subjects" do
      ref_description("Categories of data subjects affected")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "remediation" do
      ref_description("Required remediation actions if non-compliant")
      target_types(["annotation"])
      cardinality(:zero_or_more)
    end

    metadata(category: "legal_compliance", domain: "privacy", priority: "critical")
  end

  defpattern "Machine Learning Model Pattern" do
    version("1.0.0")
    description("Structured documentation of machine learning models and their characteristics")

    statement do
      template("ML Model: {model_name} - Type: {model_type} - Performance: {metrics}")
      min_length(40)
      max_length(2000)
      required_fields(["model_name", "model_type", "metrics"])
    end

    required_reference "algorithm" do
      ref_description("The machine learning algorithm used")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    required_reference "dataset" do
      ref_description("Training dataset characteristics")
      target_types(["concept"])
      cardinality(:one_or_more)
    end

    optional_reference "features" do
      ref_description("Input features used by the model")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "evaluation_metrics" do
      ref_description("Performance evaluation metrics")
      target_types(["predicate"])
      cardinality(:zero_or_more)
    end

    optional_reference "bias_assessment" do
      ref_description("Bias and fairness assessment results")
      target_types(["annotation"])
      cardinality(:zero_or_more)
    end

    metadata(category: "machine_learning", domain: "ai", priority: "high")
  end

  defpattern "Systematic Review Finding Pattern" do
    version("1.0.0")
    description("Structured capture of findings from systematic literature reviews")

    statement do
      template(
        "Review Finding: {finding} (Evidence Level: {evidence_level}, Studies: {study_count})"
      )

      min_length(50)
      max_length(3000)
      required_fields(["finding", "evidence_level", "study_count"])
    end

    required_reference "research_question" do
      ref_description("The research question this finding addresses")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    required_reference "study_methodology" do
      ref_description("Methodology used in the constituent studies")
      target_types(["concept"])
      cardinality(:one_or_more)
    end

    optional_reference "population" do
      ref_description("Study populations and sample characteristics")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "interventions" do
      ref_description("Interventions or treatments studied")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "outcomes" do
      ref_description("Measured outcomes and effect sizes")
      target_types(["predicate"])
      cardinality(:zero_or_more)
    end

    optional_reference "limitations" do
      ref_description("Study limitations and potential biases")
      target_types(["annotation"])
      cardinality(:zero_or_more)
    end

    metadata(
      category: "systematic_review",
      domain: "academic",
      priority: "high",
      quality: "evidence_based"
    )
  end

  defpattern "Clinical Trial Protocol Pattern" do
    version("1.0.0")
    description("Structured documentation of clinical trial protocols and results")

    statement do
      template("Clinical Trial: {title} - Phase: {phase} - Status: {status} - {summary}")
      min_length(60)
      max_length(4000)
      required_fields(["title", "phase", "status", "summary"])
    end

    required_reference "intervention" do
      ref_description("The intervention being tested")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    required_reference "primary_endpoint" do
      ref_description("Primary outcome measure")
      target_types(["concept"])
      cardinality(:exactly_one)
    end

    optional_reference "inclusion_criteria" do
      ref_description("Patient inclusion criteria")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "exclusion_criteria" do
      ref_description("Patient exclusion criteria")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "secondary_endpoints" do
      ref_description("Secondary outcome measures")
      target_types(["concept"])
      cardinality(:zero_or_more)
    end

    optional_reference "adverse_events" do
      ref_description("Reported adverse events and side effects")
      target_types(["annotation"])
      cardinality(:zero_or_more)
    end

    metadata(
      category: "clinical_research",
      domain: "medical",
      priority: "critical",
      regulatory: true
    )
  end
end
