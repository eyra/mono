defmodule Systems.Assignment.WorkflowItemSpecials do
  @moduledoc """
    Defines the types of workflow items supported by.
  """
  use Core.Enums.Base,
      {:assignment_workflow_item_types,
       [
         :donate,
         :questionnaire,
         :request_manual,
         :download_manual,
         :submit,
         :fork_instruction,
         :download_instruction
       ]}
end
