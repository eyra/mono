defmodule Systems.Campaign.Builders.AssignmentLandingPage do
  import CoreWeb.Gettext

  alias Core.Accounts
  alias CoreWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView

  import Frameworks.Utility.LiveCommand, only: [live_command: 2]
  import Frameworks.Utility.List

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
        } = campaign,
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
        %{user: contact} = Campaign.Context.original_author(campaign)

        %{
          public_id: member.public_id,
          subtitle: assignment_subtitle(task),
          text: assignment_text(task, expectations),
          experiment: experiment(assignment, member, user, task, contact, title)
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
         member,
         user,
         task,
         contact,
         title
       )
       when not is_nil(survey_tool) do
    actions = survey_actions(assignment, member, user, task, contact, title)

    %{
      id: :experiment_task_view,
      view: Survey.ExperimentTaskView,
      model: %{
        actions: actions
      }
    }
  end

  defp experiment(
         %{assignable_experiment: %{lab_tool: lab_tool}} = _assignment,
         member,
         user,
         task,
         contact,
         title
       )
       when not is_nil(lab_tool) do
    reservation = Lab.Context.reservation_for_user(lab_tool, user)
    actions = lab_actions(lab_tool, reservation, user, member, task, contact, title)

    %{
      id: :experiment_task_view,
      view: Lab.ExperimentTaskView,
      model: %{
        public_id: member.public_id,
        status: task.status,
        reservation: reservation,
        lab_tool: lab_tool,
        actions: actions,
        user: user
      }
    }
  end

  defp experiment(_assignment, _member, _user, _task, _contact, _title), do: nil

  # Survey buttons

  defp survey_actions(assignment, member, user, task, contact, title) do
    []
    |> append(survey_cta(assignment, member, user))
    |> append_if(contact_enabled?(task), contact_action(contact, member, title))
  end

  defp survey_cta(
         %{crew: crew, assignable_experiment: experiment} = _assignment,
         member,
         user
       ) do
    case Crew.Context.get_task(crew, member) do
      nil ->
        forward_action(user)

      task ->
        case task.status do
          :pending -> open_action(user, experiment, crew, member.public_id)
          _completed -> forward_action(user)
        end
    end
  end

  # Survey forward button

  defp forward_action(user) do
    %{
      id: :forward,
      button: %{
        action: %{type: :send, event: "forward"},
        face: %{type: :primary, label: Accounts.start_page_title(user)}
      },
      live_command: live_command(&handle_forward/2, %{user: user})
    }
  end

  def handle_forward(%{user: user}, socket) do
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))
  end

  # Survey open button

  defp open_action(user, experiment, crew, panl_id) do
    label = Assignment.ExperimentModel.open_label(experiment)
    path = Assignment.ExperimentModel.path(experiment, panl_id)

    %{
      id: :open,
      button: %{
        action: %{type: :send, event: "open"},
        face: %{type: :primary, label: label}
      },
      live_command: live_command(&handle_open/2, %{user: user, crew: crew, path: path})
    }
  end

  def handle_open(%{user: user, crew: crew, path: path}, socket) do
    member = Crew.Context.get_member!(crew, user)
    task = Crew.Context.get_task(crew, member)
    Crew.Context.lock_task(task)
    LiveView.redirect(socket, external: path)
  end

  # Lab buttons

  defp lab_actions(lab_tool, reservation, user, member, task, contact, title) do
    []
    |> append(lab_cta(lab_tool, reservation, user, task))
    |> append_if(contact_enabled?(task), contact_action(contact, member, title))
  end

  defp lab_cta(lab_tool, reservation, user, %{status: :pending}) do
    if reservation == nil do
      submit_action(user)
    else
      cancel_action(lab_tool, user)
    end
  end

  defp lab_cta(_lab_tool, _reservation, user, _task), do: forward_action(user)

  defp submit_action(user) do
    %{
      id: :submit,
      button: %{
        action: %{type: :send, event: "submit"},
        face: %{type: :primary, label: dgettext("link-lab", "timeslot.submit.button")}
      },
      live_command: live_command(&handle_submit/2, %{user: user})
    }
  end

  def handle_submit(_, %{assigns: %{selected_time_slot: nil}} = socket) do
    warning = dgettext("link-lab", "submit.warning.no.selection")
    LiveView.send_update(Dropdown.Selector, id: :dropdown_selector, model: %{warning: warning})
    socket
  end

  def handle_submit(%{user: user}, %{assigns: %{selected_time_slot: time_slot}} = socket) do
    Lab.Context.reserve_time_slot(time_slot, user)
    socket
  end

  defp cancel_action(lab_tool, user) do
    %{
      id: :cancel,
      button: %{
        action: %{type: :send, event: "cancel"},
        face: %{
          type: :secondary,
          text_color: "text-delete",
          label: dgettext("eyra-assignment", "cancel.button")
        }
      },
      live_command: live_command(&handle_cancel/2, %{lab_tool: lab_tool, user: user})
    }
  end

  def handle_cancel(%{lab_tool: lab_tool, user: user}, socket) do
    Lab.Context.cancel_reservation(lab_tool, user)
    socket |> LiveView.assign(selected_time_slot: nil)
  end

  # Contact button

  defp contact_action(%{email: email}, %{public_id: public_id}, title) do
    %{
      id: :contact,
      button: %{
        action: %{type: :href, href: contact_href(email, title, public_id)},
        face: %{type: :label, label: dgettext("eyra-assignment", "contact.button")}
      }
    }
  end

  defp contact_href(email, title, nil) do
    "mailto:#{email}?subject=#{title}"
  end

  defp contact_href(email, title, public_id) do
    "mailto:#{email}?subject=[panl_id=#{public_id}] #{title}"
  end

  # Optional behaviour

  defp contact_enabled?(%{status: :rejected}), do: true
  defp contact_enabled?(_), do: false
end
