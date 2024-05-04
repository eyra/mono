defmodule Systems.Assignment.TemplateQuestionnaire do
  import CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Workflow

  defstruct [:id]

  defimpl Assignment.Template do
    def title(t), do: Assignment.Templates.translate(t.id)

    def content_flags(_t) do
      Assignment.ContentFlags.new(opt_out: [:panel, :storage])
    end

    def workflow(_t),
      do: %Workflow.Config{
        type: :many_mandatory,
        library: %Workflow.LibraryModel{
          render?: true,
          items: [
            %Workflow.LibraryItemModel{
              special: :general_instruction,
              tool: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:general_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.general_instruction.description")
            },
            %Workflow.LibraryItemModel{
              special: :questionnaire,
              tool: :alliance_tool,
              title: Assignment.WorkflowItemSpecials.translate(:questionnaire),
              description: dgettext("eyra-assignment", "workflow_item.questionnaire.description")
            },
            %Workflow.LibraryItemModel{
              special: :onsite_experiment,
              tool: :lab_tool,
              title: Assignment.WorkflowItemSpecials.translate(:onsite_experiment),
              description:
                dgettext("eyra-assignment", "workflow_item.onsite_experiment.description")
            }
          ]
        },
        initial_items: [:questionnaire]
      }
  end
end
