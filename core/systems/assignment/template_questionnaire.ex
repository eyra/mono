defmodule Systems.Assignment.TemplateQuestionnaire do
  import CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Workflow

  defstruct [:id]

  defimpl Assignment.Template do
    alias Systems.Assignment.Template

    def title(t), do: Assignment.Templates.translate(t.id)

    def tabs(_t) do
      [
        settings: {
          dgettext("eyra-assignment", "tabbar.item.settings"),
          Template.Flags.Settings.new(opt_out: [:panel, :storage])
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Template.Flags.Workflow.new()
        },
        import: nil,
        criteria: nil,
        participants: {
          dgettext("eyra-assignment", "tabbar.item.participants"),
          Template.Flags.Participants.new()
        },
        monitor: {
          dgettext("eyra-assignment", "tabbar.item.monitor"),
          Template.Flags.Monitor.new()
        }
      ]
    end

    def workflow_config(_t),
      do: %Workflow.Config{
        singleton?: false,
        library: %Workflow.LibraryModel{
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
        initial_items: []
      }
  end
end
