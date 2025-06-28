defmodule Systems.Assignment.TemplateQuestionnaire do
  alias Systems.Assignment
  alias Systems.Workflow
  alias Frameworks.Builder

  defstruct [:id]

  defimpl Assignment.Template do
    use Gettext, backend: CoreWeb.Gettext
    alias Systems.Assignment

    def title(t), do: Assignment.Templates.translate(t.id)

    def tabs(_t) do
      [
        import: nil,
        criteria: nil,
        settings: {
          dgettext("eyra-assignment", "tabbar.item.settings"),
          Assignment.Template.Flags.Settings.new(opt_out: [:panel, :storage])
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Assignment.Template.Flags.Workflow.new()
        },
        participants: {
          dgettext("eyra-assignment", "tabbar.item.participants"),
          Assignment.Template.Flags.Participants.new()
        },
        affiliate: {
          dgettext("eyra-assignment", "tabbar.item.affiliate"),
          Assignment.Template.Flags.Affiliate.new()
        },
        monitor: {
          dgettext("eyra-assignment", "tabbar.item.monitor"),
          Assignment.Template.Flags.Monitor.new()
        }
      ]
    end

    def workflow_config(_t),
      do: %Workflow.Config{
        singleton?: false,
        library: %Builder.LibraryModel{
          items: [
            %Builder.LibraryItemModel{
              id: :manual,
              type: :manual_tool,
              title: Assignment.WorkflowItemSpecials.translate(:manual),
              description: dgettext("eyra-assignment", "workflow_item.manual.description")
            },
            %Builder.LibraryItemModel{
              id: :general_instruction,
              type: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:general_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.general_instruction.description")
            },
            %Builder.LibraryItemModel{
              id: :questionnaire,
              type: :alliance_tool,
              title: Assignment.WorkflowItemSpecials.translate(:questionnaire),
              description: dgettext("eyra-assignment", "workflow_item.questionnaire.description")
            },
            %Builder.LibraryItemModel{
              id: :onsite_experiment,
              type: :lab_tool,
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
