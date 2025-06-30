# Annotation Pattern DSL

A powerful Domain-Specific Language for defining annotation patterns using Elixir macros.

## Overview

The Pattern DSL provides a clean, declarative syntax for defining annotation patterns that ensure consistent knowledge structure across the platform. Patterns define templates, validation rules, and reference requirements for different types of knowledge annotations.

## Basic Syntax

```elixir
defmodule MyPatterns do
  use Systems.Annotation.PatternDSL
  
  defpattern "Pattern Name" do
    version "1.0.0"
    description "What this pattern is for"
    
    statement do
      template "Template with {variables}"
      min_length 10
      max_length 1000
      required_fields ["variable1", "variable2"]
    end
    
    required_reference "ref_name" do
      ref_description "What this reference is for"
      target_types ["annotation", "concept", "predicate"]
      cardinality :exactly_one
    end
    
    optional_reference "other_ref" do
      ref_description "Optional reference description"
      target_types ["concept"]
      cardinality :zero_or_more
    end
    
    metadata category: "knowledge_type", priority: "high"
  end
end
```

## DSL Components

### Pattern Definition

```elixir
defpattern "Pattern Name" do
  # Pattern configuration goes here
end
```

- Defines a new annotation pattern
- Pattern name should be descriptive and unique
- Everything inside the block configures the pattern

### Basic Metadata

```elixir
version "1.0.0"
description "Detailed description of the pattern's purpose"
```

- `version`: Semantic version for pattern evolution tracking
- `description`: Human-readable description of the pattern's purpose and use cases

### Statement Configuration

```elixir
statement do
  template "Fixed text with {variable_placeholders}"
  min_length 20
  max_length 2000
  required_fields ["variable1", "variable2"]
end
```

- `template`: Template string with variable placeholders in `{braces}`
- `min_length`: Minimum character length for statements
- `max_length`: Maximum character length for statements
- `required_fields`: List of variables that must be present in the statement

### Reference Definitions

#### Required References

```elixir
required_reference "reference_name" do
  ref_description "What this reference points to"
  target_types ["annotation", "concept", "predicate", "resource"]
  cardinality :exactly_one
end
```

#### Optional References

```elixir
optional_reference "reference_name" do
  ref_description "What this reference points to"
  target_types ["concept"]
  cardinality :zero_or_more
end
```

**Reference Properties:**
- `ref_description`: Human-readable description of the reference purpose
- `target_types`: Array of allowed target types (annotation, concept, predicate, resource)
- `cardinality`: How many targets are allowed

**Cardinality Options:**
- `:exactly_one` - Must have exactly one target
- `:zero_or_one` - May have zero or one target
- `:one_or_more` - Must have at least one target
- `:zero_or_more` - May have any number of targets

### Metadata

```elixir
metadata category: "ai_interaction", priority: "high", domain: "research"
```

- Arbitrary key-value pairs for pattern classification
- Common keys: `category`, `priority`, `domain`, `quality`, `regulatory`
- Useful for filtering and organizing patterns

## Core Patterns

The system includes several core patterns in `Systems.Annotation.CorePatterns`:

### Feedback Pattern
AI feedback on human statements for knowledge refinement.

```elixir
defpattern "Feedback Pattern" do
  version "1.0.0"
  description "Generic AI feedback on human statements for knowledge refinement"
  
  statement do
    template "AI Analysis: {analysis_content}"
    min_length 20
    max_length 2000
  end
  
  optional_reference "analyzes" do
    ref_description "The annotation being analyzed by the AI"
    target_types ["annotation"]
    cardinality :exactly_one
  end
  
  metadata category: "ai_interaction", priority: "high"
end
```

### Response Pattern
Human responses to AI feedback in the knowledge refinement loop.

### Statement Pattern
Original human statements for AI analysis and knowledge extraction.

### Definition Pattern
Formal definitions of concepts for knowledge base building.

### Validation Pattern
Human validation of AI-discovered knowledge structures.

### Research Finding Pattern
Structured research findings from literature review or studies.

### Hypothesis Pattern
Research hypotheses and theoretical propositions.

## Creating Custom Patterns

### Step 1: Create a Pattern Module

```elixir
defmodule MyApp.CustomPatterns do
  use Systems.Annotation.PatternDSL
  
  # Define patterns here
end
```

### Step 2: Define Your Patterns

```elixir
defpattern "GDPR Compliance Pattern" do
  version "1.0.0"
  description "GDPR compliance assessment and documentation"
  
  statement do
    template "GDPR Assessment: {requirement} - Status: {status}"
    min_length 30
    max_length 1500
    required_fields ["requirement", "status"]
  end
  
  required_reference "applies_to" do
    ref_description "System or process being assessed"
    target_types ["concept"]
    cardinality :exactly_one
  end
  
  metadata category: "legal_compliance", domain: "privacy"
end
```

### Step 3: Access Your Patterns

```elixir
# List all patterns
patterns = MyApp.CustomPatterns.list_patterns()

# Get a specific pattern
{:ok, pattern} = MyApp.CustomPatterns.get_pattern("GDPR Compliance Pattern")
```

## Integration with PatternManager

Patterns defined with the DSL integrate seamlessly with the PatternManager:

```elixir
# Load patterns from any module
{:ok, pattern} = Systems.Annotation.PatternManager.load_pattern("Feedback Pattern")

# List all available patterns
patterns = Systems.Annotation.PatternManager.list_available_patterns()

# Create annotations using patterns
result = Systems.Annotation.PatternManager.create_from_pattern(
  "Feedback Pattern", 
  "AI Analysis: This statement discusses machine learning concepts.",
  [],
  actor
)
```

## Advanced Features

### Domain-Specific Patterns

Create patterns tailored to specific research domains:

```elixir
defpattern "Clinical Trial Protocol Pattern" do
  version "1.0.0"
  description "Clinical trial documentation"
  
  statement do
    template "Trial: {title} - Phase: {phase} - Status: {status}"
    required_fields ["title", "phase", "status"]
  end
  
  required_reference "intervention" do
    ref_description "Intervention being tested"
    target_types ["concept"]
    cardinality :exactly_one
  end
  
  metadata category: "clinical_research", regulatory: true
end
```

### Pattern Versioning

```elixir
defpattern "Research Finding Pattern" do
  version "2.1.0"  # Updated version
  description "Enhanced research findings with effect sizes"
  
  # Updated pattern definition
end
```

### Complex Reference Structures

```elixir
required_reference "methodology" do
  ref_description "Research methodology used"
  target_types ["concept"]
  cardinality :one_or_more  # Must have at least one
end

optional_reference "limitations" do
  ref_description "Study limitations"
  target_types ["annotation"]
  cardinality :zero_or_more  # Can have many or none
end
```

## Best Practices

### 1. Descriptive Names
- Use clear, descriptive pattern names
- Include the domain or context when helpful
- Follow consistent naming conventions

### 2. Appropriate Templates
- Design templates that guide users toward structured input
- Use meaningful variable names in `{braces}`
- Include context clues in the template text

### 3. Balanced Validation
- Set reasonable length limits
- Don't over-constrain creativity
- Consider the pattern's intended use case

### 4. Meaningful References
- Define references that create useful knowledge connections
- Use appropriate cardinality constraints
- Provide clear descriptions for reference purposes

### 5. Useful Metadata
- Include metadata that helps with organization and filtering
- Use consistent metadata keys across related patterns
- Consider how patterns will be discovered and categorized

## Extending the System

### Custom Target Types

Future extensions might allow custom target types:

```elixir
# Future possibility
target_types ["dataset", "algorithm", "metric"]  # Custom types
```

### Dynamic Validation

Future features might include custom validation functions:

```elixir
# Future possibility
statement do
  template "{hypothesis}"
  custom_validation :validate_hypothesis_format
end
```

### Pattern Inheritance

Future versions might support pattern inheritance:

```elixir
# Future possibility
defpattern "Enhanced Research Pattern" do
  extends "Research Finding Pattern"
  # Additional configuration
end
```

## Troubleshooting

### Common Issues

1. **Duplicate macro names**: Ensure reference descriptions use `ref_description`, not `description`
2. **Cardinality errors**: Use atoms (`:exactly_one`) not strings (`"exactly_one"`)
3. **Missing required fields**: All patterns need `version` and `description`

### Debugging

```elixir
# Test pattern compilation
MyPatterns.list_patterns() |> IO.inspect()

# Test pattern loading
PatternManager.load_pattern("My Pattern") |> IO.inspect()
```

## Future Enhancements

### YAML Integration
When YamlElixir becomes available, patterns might be definable in YAML:

```yaml
patterns:
  - name: "GDPR Pattern"
    version: "1.0.0"
    description: "GDPR compliance assessment"
    statement:
      template: "Assessment: {requirement}"
      min_length: 20
```

### Visual Pattern Editor
A future web interface might provide visual pattern creation and editing capabilities.

### Pattern Analytics
Future features might include analytics on pattern usage, effectiveness, and evolution.

## Conclusion

The Pattern DSL provides a powerful, flexible way to define structured annotation patterns that ensure consistent knowledge capture across the platform. By using Elixir macros, patterns are compiled at build time, providing excellent performance and early error detection while maintaining clean, readable definitions.