defmodule Systems.Assignment.TemplatePaperScreening do
  alias Systems.Assignment
  alias Systems.Workflow

  import CoreWeb.Gettext

  defstruct [:id]

  defimpl Assignment.Template do
    alias Systems.Assignment.Template

    def title(t), do: Assignment.Templates.translate(t.id)

    def tabs(_t) do
      [
        settings: nil,
        workflow: nil,
        import: {
          dgettext("eyra-assignment", "tabbar.item.import"),
          Template.Flags.Import.new()
        },
        criteria: {
          dgettext("eyra-assignment", "tabbar.item.criteria"),
          Template.Flags.Criteria.new()
        },
        participants: {
          dgettext("eyra-assignment", "tabbar.item.reviewers"),
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
        singleton?: true,
        library: %Workflow.LibraryModel{
          items: [
            %Workflow.LibraryItemModel{
              special: :paper_screening,
              tool: :onyx_tool,
              title: Assignment.WorkflowItemSpecials.translate(:paper_screening),
              description:
                dgettext("eyra-assignment", "workflow_item.paper_screening.description")
            }
          ]
        },
        initial_items: [:paper_screening]
      }
  end
end
