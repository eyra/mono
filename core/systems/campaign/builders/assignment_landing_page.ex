defmodule Systems.Campaign.Builders.AssignmentLandingPage do
  import CoreWeb.Gettext

  alias Core.Accounts
  alias CoreWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView

  import Frameworks.Utility.LiveCommand, only: [live_command: 2]

  alias Systems.{
    Campaign,
    Assignment,
    Crew,
    Survey,
    Lab
  }

  def view_model(
        %{
          id: id,
          promotion: %{
            expectations: expectations,
            title: title,
            submission: submission
          },
          promotable_assignment:
            %{
              crew: crew
            } = assignment
        },
        user,
        _url_resolver
      ) do
    base = %{
      id: id,
      title: title,
      highlights: highlights(assignment, submission),
      hero_title: dgettext("link-survey", "task.hero.title")
    }

    extra =
      if Crew.Context.member?(crew, user) do
        member = Crew.Context.get_member!(crew, user)
        task = Crew.Context.get_task(crew, member)

        %{
          public_id: member.public_id,
          subtitle: assignment_subtitle(task),
          text: assignment_text(task, expectations),
          experiment: experiment(assignment, member, user, task)
        }
      else
        # probably expired member
        %{
          subtitle: dgettext("eyra-crew", "task.expired.subtitle"),
          text: dgettext("eyra-crew", "task.expired.text"),
          experiment: nil
        }
      end

    Map.merge(base, extra)
  end

  # Subtitle
  defp assignment_subtitle(%{status: :pending}),
    do: dgettext("link-survey", "task.pending.subtitle")

  defp assignment_subtitle(%{status: :completed}),
    do: dgettext("link-survey", "task.completed.subtitle")

  defp assignment_subtitle(%{status: :accepted}),
    do: dgettext("link-survey", "task.accepted.subtitle")

  defp assignment_subtitle(%{status: :rejected}),
    do: dgettext("link-survey", "task.rejected.subtitle")

  defp assignment_subtitle(_),
    do: dgettext("eyra-promotion", "expectations.public.label")

  # Text
  defp assignment_text(%{status: :completed}, _),
    do: dgettext("link-survey", "task.completed.text")

  defp assignment_text(%{status: :accepted}, _), do: dgettext("link-survey", "task.accepted.text")

  defp assignment_text(%{status: :rejected, rejected_message: rejected_message}, _) do
    dgettext("link-survey", "task.rejected.text", reason: rejected_message)
  end

  defp assignment_text(_, expectations), do: expectations

  # Highlights

  defp highlights(assignment, submission) do
    [
      Campaign.Builders.Highlight.view_model(assignment, :duration),
      Campaign.Builders.Highlight.view_model(assignment, :language),
      Campaign.Builders.Highlight.view_model(submission, :reward)
    ]
  end

  # Experiment

  defp experiment(
         %{assignable_experiment: %{survey_tool: survey_tool}} = assignment,
         %{public_id: public_id} = member,
         user,
         task
       )
       when not is_nil(survey_tool) do
    %{
      id: :experiment_task_view,
      view: Survey.ExperimentTaskView,
      model: %{
        public_id: public_id,
        call_to_action: survey_call_to_action(assignment, member, user),
        contact_enabled?: contact_enabled?(task),
        owner: Assignment.Context.owner!(assignment)
      }
    }
  end

  defp experiment(
         %{assignable_experiment: %{lab_tool: lab_tool}} = assignment,
         _member,
         user,
         task
       )
       when not is_nil(lab_tool) do
    reservation = Lab.Context.reservation_for_user(lab_tool, user)

    %{
      id: :experiment_task_view,
      view: Lab.ExperimentTaskView,
      model: %{
        reservation: reservation,
        lab_tool: lab_tool,
        contact_enabled?: contact_enabled?(task),
        user: user,
        owner: Assignment.Context.owner!(assignment)
      }
    }
  end

  defp experiment(_assignment, _member, _user, _task), do: nil

  defp survey_call_to_action(
         %{crew: crew, assignable_experiment: experiment} = _assignment,
         member,
         user
       ) do
    case Crew.Context.get_task(crew, member) do
      nil ->
        forward_call_to_action(user)

      task ->
        case task.status do
          :pending -> open_call_to_action(user, experiment, crew, member.public_id)
          _completed -> forward_call_to_action(user)
        end
    end
  end

  # Forward button

  defp forward_call_to_action(user) do
    %{
      label: Accounts.start_page_title(user),
      type: %{type: :event, value: "forward"},
      live_command: live_command(&handle_forward/2, %{user: user})
    }
  end

  def handle_forward(%{user: user}, socket) do
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))
  end

  # Open button

  defp open_call_to_action(user, experiment, crew, panl_id) do
    label = Assignment.ExperimentModel.open_label(experiment)
    path = Assignment.ExperimentModel.path(experiment, panl_id)

    %{
      label: label,
      target: %{type: :event, value: "open"},
      live_command: live_command(&handle_open/2, %{user: user, crew: crew, path: path})
    }
  end

  def handle_open(%{user: user, crew: crew, path: path}, socket) do
    member = Crew.Context.get_member!(crew, user)
    task = Crew.Context.get_task(crew, member)
    Crew.Context.lock_task(task)
    LiveView.redirect(socket, external: path)
  end

  # Optional behaviour

  defp contact_enabled?(%{status: :rejected}), do: true
  defp contact_enabled?(_), do: false
end
