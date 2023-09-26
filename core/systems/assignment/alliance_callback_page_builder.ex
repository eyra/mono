defmodule Systems.Assignment.AllianceCallbackPageBuilder do
  import CoreWeb.Gettext

  alias Core.Accounts
  alias Core.Authorization
  alias Phoenix.LiveView

  alias Systems.{
    Assignment,
    Workflow,
    Alliance
  }

  def view_model(
        %Alliance.ToolModel{id: id} = tool,
        %{current_user: user} = _assigns
      ) do
    %{title: title} = Workflow.Public.get_item_by_tool!(:alliance_tool, tool.id)
    assignment = Assignment.Public.get_by_tool(tool)

    %{
      id: id,
      title: title,
      state: state(assignment, user),
      hero_title: dgettext("link-questionnaire", "task.hero.title"),
      call_to_action: forward_call_to_action(user)
    }
  end

  defp state(%{crew: crew} = assignment, user) do
    if Assignment.Public.member?(assignment, user) do
      :participant
    else
      if Authorization.user_has_role?(user, crew, :tester) do
        :tester
      else
        :expired
      end
    end
  end

  defp forward_call_to_action(user) do
    %{
      label: Accounts.start_page_title(user),
      target: %{type: :event, value: "forward"},
      handle: &handle_forward/1
    }
  end

  def handle_forward(%{assigns: %{current_user: user}} = socket) do
    LiveView.push_redirect(socket, to: Accounts.start_page_path(user))
  end
end
