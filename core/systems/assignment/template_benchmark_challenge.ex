defmodule Systems.Assignment.TemplateBenchmarkChallenge do
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
          Template.Flags.Settings.new(opt_out: [:language, :panel, :storage])
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Template.Flags.Workflow.new()
        },
        import: nil,
        criteria: nil,
        participants: {
          dgettext("eyra-assignment", "tabbar.item.participants"),
          Template.Flags.Participants.new(opt_out: [:advert_in_pool])
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
