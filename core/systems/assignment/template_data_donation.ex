defmodule Systems.Assignment.TemplateDataDonation do
  alias Systems.Assignment
  alias Systems.Workflow

  import CoreWeb.Gettext

  defstruct [:id]

  defimpl Assignment.Template do
    def title(t), do: Assignment.Templates.translate(t.id)

    def content_flags(_t) do
      Assignment.ContentFlags.new(opt_out: [:invite_participants, :advert_in_pool])
    end

    def workflow(_t),
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
