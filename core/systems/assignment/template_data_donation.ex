defmodule Systems.Assignment.TemplateDataDonation do
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
        settings: {
          dgettext("eyra-assignment", "tabbar.item.settings"),
          Assignment.Template.Flags.Settings.new()
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Assignment.Template.Flags.Workflow.new()
        },
        import: nil,
        criteria: nil,
        participants: nil,
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
              id: :donate,
              type: :feldspar_tool,
              title: Assignment.WorkflowItemSpecials.translate(:donate),
              description: dgettext("eyra-assignment", "workflow_item.donate.description")
            },
            %Builder.LibraryItemModel{
              id: :questionnaire,
              type: :alliance_tool,
              title: Assignment.WorkflowItemSpecials.translate(:questionnaire),
              description: dgettext("eyra-assignment", "workflow_item.questionnaire.description")
            },
            %Builder.LibraryItemModel{
              id: :request_manual,
              type: :document_tool,
              title: Assignment.WorkflowItemSpecials.translate(:request_manual),
              description: dgettext("eyra-assignment", "workflow_item.request.description")
            },
            %Builder.LibraryItemModel{
              id: :download_manual,
              type: :document_tool,
              title: Assignment.WorkflowItemSpecials.translate(:download_manual),
              description: dgettext("eyra-assignment", "workflow_item.download.description")
            }
          ]
        },
        initial_items: []
      }
  end
end
