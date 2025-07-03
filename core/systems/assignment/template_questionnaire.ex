defmodule Systems.Assignment.TemplateQuestionnaire do
  alias Systems.Assignment
  alias Systems.Workflow

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
          Assignment.Template.Flags.Settings.new(
            opt_in: [
              :branding,
              :information,
              :privacy,
              :consent,
              :helpdesk,
              :affiliate
            ]
          )
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Assignment.Template.Flags.Workflow.new()
        },
        participants: {
          dgettext("eyra-assignment", "tabbar.item.participants"),
          Assignment.Template.Flags.Participants.new(
            opt_in: [
              :language_fixed_nl,
              :expected,
              :language,
              :advert_in_pool,
              :invite_participants
            ]
          )
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
        library: %Workflow.LibraryModel{
          items: [
            %Workflow.LibraryItemModel{
              special: :manual,
              tool: :manual_tool,
              title: Assignment.WorkflowItemSpecials.translate(:manual),
              description: dgettext("eyra-assignment", "workflow_item.manual.description")
            },
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
