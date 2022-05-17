defmodule Systems.Campaign.Builders.AssignmentCallbackPage do
  import CoreWeb.Gettext

  alias Core.Accounts
  alias Core.Authorization
  alias CoreWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView

  alias Systems.{
    Assignment
  }

  def view_model(
        %{
          id: id,
          promotion: %{
            title: title
          },
          promotable_assignment: assignment
        },
        %{current_user: user} = _assigns,
        _url_resolver
      ) do
    %{
      id: id,
      title: title,
      state: state(assignment, user),
      hero_title: dgettext("link-survey", "task.hero.title"),
      call_to_action: forward_call_to_action(user)
    }
  end

  defp state(%{crew: crew} = assignment, user) do
    if Assignment.Context.activate_task(assignment, user) do
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
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))
  end
end
