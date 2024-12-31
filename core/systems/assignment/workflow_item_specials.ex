defmodule Systems.Assignment.WorkflowItemSpecials do
  @moduledoc """
    Defines the types of workflow items supported by.
  """
  use Core.Enums.Base,
      {:assignment_workflow_item_types,
       [
         :questionnaire,
         :onsite_experiment,
         :donate,
         :submit,
         :request_manual,
         :download_manual,
         :fork_instruction,
         :download_instruction,
         :general_instruction,
         :paper_screening
       ]}
end
