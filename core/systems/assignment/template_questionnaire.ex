defmodule Systems.Assignment.TemplateQuestionnaire do
  alias Systems.Assignment
  alias Systems.Workflow
  alias Frameworks.Builder

  defstruct [:id]

  defimpl Assignment.Template do
    use Gettext, backend: CoreWeb.Gettext
    use Core.FeatureFlags
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
          Assignment.Template.Flags.Participants.new(opt_in: participants_opt_in())
        },
        contributions: contributions_tab(),
        monitor: {
          dgettext("eyra-assignment", "tabbar.item.monitor"),
          Assignment.Template.Flags.Monitor.new()
        }
      ]
    end

    defp participants_opt_in do
      [:recruit_participants] ++
        if feature_enabled?(:panl_post_launch),
          do: [:advert_in_pool, :paid_slots],
          else: []
    end

    # Contributions is only meaningful when paid_slots is on — otherwise
    # there's nothing to approve/decline. Same gate as the Participants
    # paid_slots opt-in so the two surfaces stay in sync.
    defp contributions_tab do
      if feature_enabled?(:panl_post_launch) do
        {
          dgettext("eyra-assignment", "tabbar.item.contributions"),
          Assignment.Template.Flags.Contributions.new()
        }
      end
    end

    def currency(_t), do: :EUR

    def runtime_config(_t),
      do: %Assignment.RuntimeConfig{pool: :panl}

    def workflow_config(_t),
      do: %Workflow.Config{
        singleton?: false,
        group_enabled?: false,
        library: %Builder.LibraryModel{
          items: [
            %Builder.LibraryItemModel{
              id: :manual,
              type: :manual_tool,
              title: Assignment.WorkflowItemSpecials.translate(:manual),
              description: dgettext("eyra-assignment", "workflow_item.manual.description")
            },
            %Builder.LibraryItemModel{
              id: :questionnaire,
              type: :alliance_tool,
              title: Assignment.WorkflowItemSpecials.translate(:questionnaire),
              description: dgettext("eyra-assignment", "workflow_item.questionnaire.description")
            }
          ]
        },
        initial_items: []
      }
  end
end
