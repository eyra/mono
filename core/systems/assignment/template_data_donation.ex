defmodule Systems.Assignment.TemplateDataDonation do
  alias Systems.Assignment
  alias Systems.Workflow

  import CoreWeb.Gettext

  defstruct [:id]

  defimpl Assignment.Template do
    alias Systems.Assignment.Template

    def title(t), do: Assignment.Templates.translate(t.id)

    def tabs(_t) do
      [
        settings: {
          dgettext("eyra-assignment", "tabbar.item.settings"),
          Template.Flags.Settings.new()
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Template.Flags.Workflow.new()
        },
        import: nil,
        criteria: nil,
        participants: nil,
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
              special: :donate,
              tool: :feldspar_tool,
              title: Assignment.WorkflowItemSpecials.translate(:donate),
              description: dgettext("eyra-assignment", "workflow_item.donate.description")
            },
            %Workflow.LibraryItemModel{
              special: :questionnaire,
              tool: :alliance_tool,
              title: Assignment.WorkflowItemSpecials.translate(:questionnaire),
              description: dgettext("eyra-assignment", "workflow_item.questionnaire.description")
            },
            %Workflow.LibraryItemModel{
              special: :request_manual,
              tool: :document_tool,
              title: Assignment.WorkflowItemSpecials.translate(:request_manual),
              description: dgettext("eyra-assignment", "workflow_item.request.description")
            },
            %Workflow.LibraryItemModel{
              special: :download_manual,
              tool: :document_tool,
              title: Assignment.WorkflowItemSpecials.translate(:download_manual),
              description: dgettext("eyra-assignment", "workflow_item.download.description")
            }
          ]
        },
        initial_items: []
      }
  end
end
