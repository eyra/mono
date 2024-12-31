defmodule Systems.Assignment.TemplatePaperScreening do
  use Gettext, backend: CoreWeb.Gettext
  alias Systems.Assignment
  alias Systems.Workflow

  defstruct [:id]

  defimpl Assignment.Template do
    use Gettext, backend: CoreWeb.Gettext
    alias Systems.Assignment

    def title(t), do: Assignment.Templates.translate(t.id)

    def tabs(_t) do
      [
        settings: nil,
        workflow: nil,
        import: {
          dgettext("eyra-assignment", "tabbar.item.import"),
          Assignment.Template.Flags.Import.new()
        },
        criteria: {
          dgettext("eyra-assignment", "tabbar.item.criteria"),
          Assignment.Template.Flags.Criteria.new()
        },
        participants: {
          dgettext("eyra-assignment", "tabbar.item.reviewers"),
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
