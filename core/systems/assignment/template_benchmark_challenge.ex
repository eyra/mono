defmodule Systems.Assignment.TemplateBenchmarkChallenge do
  alias Systems.Assignment
  alias Systems.Workflow

  import CoreWeb.Gettext

  defstruct [:id]

  defimpl Assignment.Template do
    def title(t), do: Assignment.Templates.translate(t.id)

    def content_flags(_t) do
      Map.merge(Assignment.ContentFlags.new(), %{
        panel: false,
        storage: false
      })
    end

    def workflow(_t),
      do: %Workflow.Config{
        type: :many_mandatory,
        library: %Workflow.LibraryModel{
          render?: true,
          items: [
            %Workflow.LibraryItemModel{
              special: :fork_instruction,
              tool: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:fork_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.fork_instruction.description")
            },
            %Workflow.LibraryItemModel{
              special: :download_instruction,
              tool: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:download_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.download_instruction.description")
            },
            %Workflow.LibraryItemModel{
              special: :submit,
              tool: :graphite_tool,
              title: Assignment.WorkflowItemSpecials.translate(:submit),
              description: dgettext("eyra-assignment", "workflow_item.submit.description")
            }
          ]
        },
        initial_items: [:fork_instruction, :download_instruction, :submit]
      }
  end
end
