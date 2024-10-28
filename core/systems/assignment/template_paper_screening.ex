defmodule Systems.Assignment.TemplatePaperScreening do
  alias Systems.Assignment
  alias Systems.Workflow

  import CoreWeb.Gettext

  defstruct [:id]

  defimpl Assignment.Template do
    def title(t), do: Assignment.Templates.translate(t.id)

    def content_flags(_t) do
      Assignment.ContentFlags.new(opt_out: [:settings, :advert_in_pool])
    end

    def workflow(_t),
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
