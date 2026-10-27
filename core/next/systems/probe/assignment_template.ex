defmodule Systems.Probe.AssignmentTemplate do
  @moduledoc """
  Assignment template for cognitive tools: zip apps that run like Feldspar apps
  but are cognitive tasks, not data donations. Consent, storage of results and
  completion are those of the Feldspar tool, as in the Data donation template;
  only the texts differ. Behind the `:probe` feature flag.
  """
  @behaviour Systems.Assignment.TemplateExtension

  use Core.FeatureFlags
  use Gettext, backend: CoreWeb.Gettext

  defstruct [:id]

  @impl true
  def id, do: :probe

  @impl true
  def enabled?, do: feature_enabled?(:probe)

  @impl true
  def tool_description(:cognitive_tool), do: dgettext("eyra-probe", "tool.description")
  def tool_description(_special), do: nil

  defimpl Systems.Assignment.Template do
    use Gettext, backend: CoreWeb.Gettext

    alias Frameworks.Builder
    alias Systems.Assignment
    alias Systems.Workflow

    def title(_t), do: dgettext("eyra-probe", "template.title")

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
          Assignment.Template.Flags.Participants.new(opt_in: [:expected, :language, :affiliate])
        },
        affiliate: {
          dgettext("eyra-assignment", "tabbar.item.affiliate"),
          Assignment.Template.Flags.Affiliate.new()
        },
        monitor: {
          dgettext("eyra-assignment", "tabbar.item.monitor"),
          Assignment.Template.Flags.Monitor.new()
        }
      ]
    end

    def runtime_config(_t), do: %Assignment.RuntimeConfig{}

    def currency(_t), do: :EUR

    def workflow_config(_t),
      do: %Workflow.Config{
        singleton?: false,
        library: %Builder.LibraryModel{
          items: [
            %Builder.LibraryItemModel{
              id: :cognitive_tool,
              type: :feldspar_tool,
              title: dgettext("eyra-probe", "workflow_item.cognitive_tool.title"),
              description: dgettext("eyra-probe", "workflow_item.cognitive_tool.description")
            },
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
