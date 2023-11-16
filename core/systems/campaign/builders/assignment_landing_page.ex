defmodule Systems.Campaign.Builders.AssignmentLandingPage do
  import CoreWeb.Gettext

  alias Core.Accounts

  import Frameworks.Utility.LiveCommand, only: [live_command: 2]
  import Frameworks.Utility.List

  alias Frameworks.Pixel.DropdownSelector

  alias Systems.{
    Campaign,
    Assignment,
    Workflow,
    Crew,
    Alliance,
    Lab,
    Budget
  }

  def view_model(
        %Campaign.Model{} = campaign,
        assigns
      ) do
    campaign
    |> Campaign.Model.flatten()
    |> view_model(assigns)
  end

  def view_model(campaign, assigns) do
    base = base(campaign, assigns)
    extra = extra(campaign, assigns)

    Map.merge(base, extra)
  end

  defp base(
         %{
           id: id,
           promotion: %{
             title: title
           },
           promotable: assignment
         },
         %{current_user: user}
       ) do
    reward =
      Assignment.Public.idempotence_key(assignment, user)
      |> Budget.Public.get_reward(budget: [currency: Budget.CurrencyModel.preload_graph(:full)])

    %{
      id: id,
      title: title,
      highlights: highlights(assignment, reward),
      hero_title: dgettext("eyra-alliance", "task.hero.title")
    }
  end

  defp extra(
         %{promotable: %{crew: crew}} = campaign,
         %{current_user: user} = assigns
       ) do
    tasks = Crew.Public.list_tasks_for_user(crew, user)
    extra(tasks, campaign, assigns)
  end

  defp extra(
         [task],
         %{
           promotion: %{
             title: title,
             expectations: expectations
           },
           promotable:
             %{
               crew: crew,
               workflow: workflow
             } = assignment
         } = campaign,
         %{current_user: user}
       ) do
    member = Crew.Public.get_member(crew, user)
    %{user: contact} = Campaign.Public.original_author(campaign)
    [tool | _] = Workflow.Model.flatten(workflow)

    %{
      public_id: member.public_id,
      subtitle: assignment_subtitle(task),
      text: assignment_text(task, expectations),
      task: task(assignment, tool, member, user, task, contact, title)
    }
  end

  defp extra(_, _, _) do
    # probably expired member
    %{
      public_id: nil,
      subtitle: dgettext("eyra-crew", "task.expired.subtitle"),
      text: dgettext("eyra-crew", "task.expired.text"),
      task: nil
    }
  end

  # Subtitle
  defp assignment_subtitle(%{status: :pending}),
    do: dgettext("eyra-alliance", "task.pending.subtitle")

  defp assignment_subtitle(%{status: :completed}),
    do: dgettext("eyra-alliance", "task.completed.subtitle")

  defp assignment_subtitle(%{status: :accepted}),
    do: dgettext("eyra-alliance", "task.accepted.subtitle")

  defp assignment_subtitle(%{status: :rejected}),
    do: dgettext("eyra-alliance", "task.rejected.subtitle")

  defp assignment_subtitle(_),
    do: dgettext("eyra-promotion", "expectations.public.label")

  # Text
  defp assignment_text(%{status: :completed}, _),
    do: dgettext("eyra-alliance", "task.completed.text")

  defp assignment_text(%{status: :accepted}, _),
    do: dgettext("eyra-alliance", "task.accepted.text")

  defp assignment_text(%{status: :rejected, rejected_message: rejected_message}, _) do
    dgettext("eyra-alliance", "task.rejected.text", reason: rejected_message)
  end

  defp assignment_text(_, expectations), do: expectations

  # Highlights

  defp highlights(assignment, nil) do
    [
      Campaign.Builders.Highlight.view_model(assignment, :duration),
      Campaign.Builders.Highlight.view_model(assignment, :language)
    ]
  end

  defp highlights(assignment, reward) do
    highlights(assignment, nil) ++ [Campaign.Builders.Highlight.view_model(reward, :reward)]
  end

  # Inquiry

  defp task(
         assignment,
         %Alliance.ToolModel{} = tool,
         member,
         user,
         task,
         contact,
         title
       ) do
    actions = alliance_actions(assignment, tool, member, user, task, contact, title)

    %{
      id: :task_view,
      view: Alliance.TaskView,
      model: %{
        actions: actions
      }
    }
  end

  defp task(
         _assignment,
         %Lab.ToolModel{} = tool,
         member,
         user,
         task,
         contact,
         title
       ) do
    reservation = Lab.Public.reservation_for_user(tool, user)
    actions = lab_actions(tool, reservation, user, member, task, contact, title)

    %{
      id: :task_view,
      view: Lab.TaskView,
      model: %{
        public_id: member.public_id,
        status: task.status,
        reservation: reservation,
        lab_tool: tool,
        actions: actions,
        user: user
      }
    }
  end

  defp task(_assignment, _tool, _member, _user, _task, _contact, _title), do: nil

  # Alliance buttons

  defp alliance_actions(assignment, tool, member, user, task, contact, title) do
    []
    |> append(alliance_cta(assignment, tool, member, user))
    |> append_if(contact_enabled?(task), contact_action(contact, member, title))
  end

  defp alliance_cta(
         %{crew: crew} = _assignment,
         tool,
         member,
         user
       ) do
    case Crew.Public.list_tasks_for_user(crew, user) do
      nil ->
        forward_action(user)

      [task] ->
        case task.status do
          :pending -> open_action(user, tool, crew, member.public_id)
          _completed -> forward_action(user)
        end
    end
  end

  # Alliance forward button

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
    Phoenix.LiveView.push_redirect(socket, to: Accounts.start_page_path(user))
  end

  # Alliance open button

  defp open_action(user, tool, crew, next_id) do
    label = Frameworks.Concept.ToolModel.open_label(tool)
    path = Alliance.ToolModel.external_path(tool, next_id)

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
    [task] = Crew.Public.list_tasks_for_user(crew, user)
    Crew.Public.lock_task(task)
    Phoenix.LiveView.redirect(socket, external: path)
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

    Phoenix.LiveView.send_update(DropdownSelector,
      id: :dropdown_selector,
      model: %{warning: warning}
    )

    socket
  end

  def handle_submit(%{user: user}, %{assigns: %{selected_time_slot: time_slot}} = socket) do
    Lab.Public.reserve_time_slot(time_slot, user)
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
    Lab.Public.cancel_reservation(lab_tool, user)
    socket |> Phoenix.Component.assign(selected_time_slot: nil)
  end

  # Contact button

  defp contact_action(%{email: email}, %{public_id: public_id}, title) do
    %{
      id: :contact,
      button: %{
        action: %{type: :http_get, to: contact_href(email, title, public_id)},
        face: %{type: :label, label: dgettext("eyra-assignment", "contact.button")}
      }
    }
  end

  defp contact_href(email, title, nil) do
    "mailto:#{email}?subject=#{title}"
  end

  defp contact_href(email, title, public_id) do
    "mailto:#{email}?subject=[next_id=#{public_id}] #{title}"
  end

  # Optional behaviour

  defp contact_enabled?(%{status: :rejected}), do: true
  defp contact_enabled?(_), do: false
end
