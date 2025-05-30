defmodule Systems.Assignment.TemplateBenchmarkChallenge do
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
          Assignment.Template.Flags.Settings.new(opt_out: [:language, :panel, :storage])
        },
        workflow: {
          dgettext("eyra-assignment", "tabbar.item.workflow"),
          Assignment.Template.Flags.Workflow.new()
        },
        import: nil,
        criteria: nil,
        participants: {
          dgettext("eyra-assignment", "tabbar.item.participants"),
          Assignment.Template.Flags.Participants.new(opt_out: [:advert_in_pool])
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
              id: :fork_instruction,
              type: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:fork_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.fork_instruction.description")
            },
            %Builder.LibraryItemModel{
              id: :download_instruction,
              type: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:download_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.download_instruction.description")
            },
            %Builder.LibraryItemModel{
              id: :submit,
              type: :graphite_tool,
              title: Assignment.WorkflowItemSpecials.translate(:submit),
              description: dgettext("eyra-assignment", "workflow_item.submit.description")
            }
          ]
        },
        initial_items: [:fork_instruction, :download_instruction, :submit]
      }
  end
end
