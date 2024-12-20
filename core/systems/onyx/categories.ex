defmodule Systems.Onyx.Categories do
  @moduledoc """
  Defines the screening criteria categories used in the TIAB screening phase of the literature review.

  ## Purpose
  This module specifies a focused subset of research elements (categories) derived from established frameworks
  like PICO, PICo, SPIDER, and SPICE. These categories are used to guide the screening process by structuring
  the evaluation of titles and abstracts (TIAB). The categories provide a conceptual foundation for assessing
  paper relevance.

  ## Current Scope
  The categories in this module are scoped specifically to the TIAB screening phase of a literature review.
  They are not intended to represent the entirety of any framework but instead focus on elements most relevant
  for this phase of the research process.

  | **Category**               | **Description**                                  | **Framework of Origin** |
  |----------------------------|--------------------------------------------------|-------------------------|
  | **Population**             | The group, subjects, or sample being studied.    | PICO, PICo, SPIDER      |
  | **Intervention**           | The treatment, exposure, or action studied.      | PICO, SPICE             |
  | **Comparison**             | The control group or alternative intervention.   | PICO, SPICE             |
  | **Outcome**                | The measurable result of the intervention.       | PICO, PICOS, SPICE      |
  | **Phenomenon of Interest** | The qualitative research focus.                  | SPIDER, PICo            |
  | **Context**                | The environment, setting, or situational focus.  | PICo, SPICE             |
  | **Setting**                | A specific geographic or organizational location.| SPICE                   |

  ## Future Integration
  ### Ontology-Based Annotation Labels
  - These categories will eventually be replaced by **Annotation Labels** represented as **Terms** in the
  Onyx Ontology.

  - Each Term will have:
    - **Multiple Definitions**: Reflecting different interpretations across domains and study types.
    - **Context-Dependent Mapping**: Definitions will adapt dynamically based on the researcher's context,
    such as the type of study they are conducting.

  ### Mappings in Onyx
  - Onyx will define mappings between:
    - **Ontology Terms**: Categories as Ontology Terms.
    - **Study Contexts**: Study types provided by the researcher.
    - These mappings ensure precise and flexible use of terms across diverse scientific disciplines.

  ## Note
  The current implementation focuses on the immediate needs of the TIAB screening phase. However, the modular
  design ensures future adaptability as Onyx evolves to incorporate an ontology-driven framework for annotations.

  ## Usage
  ### In the Screening Process
  These categories are used to structure the evaluation criteria applied during the TIAB screening phase. They
  guide both manual reviews and AI-assisted tools to assess paper relevance against predefined criteria.

  ### Transition to Ontology
  As Onyx develops, these categories will form the conceptual basis for a broader, ontology-driven annotation
  framework, ensuring scalability and cross-domain applicability.

  """

  use Core.Enums.Base,
      {:categories,
       [
         :population,
         :intervention,
         :comparison,
         :outcome,
         :phenomenon_of_interest,
         :context,
         :setting
       ]}
end
