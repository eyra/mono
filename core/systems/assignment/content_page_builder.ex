defmodule Systems.Assignment.ContentPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias Frameworks.Utility.List

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Monitor

  @moduledoc """
    Assignment is a generic concept with a template pattern. The content page is therefor rendered with optional components.
    This builder module supports several specials with each a specific View Model.
    For a full overview of the template feature see `Systems.Assignment.Template`.
  """

  @doc """
    Returns a view model based on the templates defined in:
    * Benchmark Challenge: `Systems.Assignment.TemplateBenchmarkChallenge`
    * Data Donation: `Systems.Assignment.TemplateDataDonation`
    * Questionnaire: `Systems.Assignment.TemplateQuestionnaire`
  """
  def view_model(
        %{id: id} = assignment,
        assigns
      ) do
    template = Assignment.Private.get_template(assignment)
    show_errors = show_errors(assignment, assigns)
    tabs = create_tabs(assignment, template, show_errors, assigns)
    action_map = action_map(assignment, assigns)
    actions = actions(assignment, action_map)

    %{
      id: id,
      title: Assignment.Template.title(template),
      tabs: tabs,
      actions: actions,
      show_errors: show_errors
    }
  end

  defp show_errors(_, _) do
    # concept? = status == :concept
    # publish_clicked or not concept?
    false
  end

  defp action_map(assignment, %{current_user: %{id: user_id}}) do
    preview_url = Assignment.Private.get_preview_url(assignment, user_id)

    preview_action = %{type: :http_get, to: preview_url, target: "_blank"}
    publish_action = %{type: :send, event: "action_click", item: :publish}
    retract_action = %{type: :send, event: "action_click", item: :retract}
    close_action = %{type: :send, event: "action_click", item: :close}
    open_action = %{type: :send, event: "action_click", item: :open}

    %{
      preview: %{
        label: %{
          action: preview_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-assignment", "preview.button")}
        }
      },
      publish: %{
        label: %{
          action: publish_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "publish.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: publish_action,
          face: %{type: :icon, icon: :publish, alt: dgettext("eyra-assignment", "preview.button")}
        },
        handle_click: &handle_publish/1
      },
      retract: %{
        label: %{
          action: retract_action,
          face: %{
            type: :secondary,
            label: dgettext("eyra-assignment", "retract.button"),
            text_color: "text-error",
            border_color: "border-error"
          }
        },
        icon: %{
          action: retract_action,
          face: %{
            type: :icon,
            icon: :retract,
            alt: dgettext("eyra-graphite", "assignment.button")
          }
        },
        handle_click: &handle_retract/1
      },
      close: %{
        label: %{
          action: close_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "close.button")
          }
        },
        icon: %{
          action: close_action,
          face: %{type: :icon, icon: :close, alt: dgettext("eyra-assignment", "close.button")}
        },
        handle_click: &handle_close/1
      },
      open: %{
        label: %{
          action: open_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "open.button")
          }
        },
        icon: %{
          action: open_action,
          face: %{type: :icon, icon: :open, alt: dgettext("eyra-assignment", "open.button")}
        },
        handle_click: &handle_open/1
      }
    }
  end

  defp actions(%{status: :online}, %{retract: retract}), do: [retract: retract]

  defp actions(%{status: :offline}, %{publish: publish, close: close}),
    do: [publish: publish, close: close]

  defp actions(%{status: :idle}, %{open: open}), do: [open: open]

  defp actions(%{status: _concept}, %{publish: publish, preview: preview}),
    do: [publish: publish, preview: preview]

  defp handle_publish(socket) do
    socket |> set_status(:online)
  end

  defp handle_retract(socket) do
    socket |> set_status(:offline)
  end

  defp handle_close(socket) do
    socket |> set_status(:idle)
  end

  defp handle_open(socket) do
    socket |> set_status(:concept)
  end

  defp set_status(%{assigns: %{model: assignment}} = socket, status) do
    {:ok, assignment} = Assignment.Public.update(assignment, %{status: status})
    socket |> Phoenix.Component.assign(model: assignment)
  end

  defp create_tabs(assignment, template, show_errors, assigns) do
    get_tab_keys(Assignment.Template.content_flags(template))
    |> Enum.map(&create_tab(&1, assignment, template, show_errors, assigns))
  end

  defp get_tab_keys(%{} = config) do
    [:settings]
    |> List.append_if(:workflow, config[:workflow])
    |> List.append_if(:participants, config[:invite_participants] or config[:advert_in_pool])
    |> List.append_if(:monitor, config[:monitor])
  end

  defp create_tab(
         :settings,
         assignment,
         template,
         show_errors,
         %{fabric: fabric, uri_origin: uri_origin, viewport: viewport, breakpoint: breakpoint} =
           _assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :settings_form, Assignment.SettingsView, %{
        entity: assignment,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
        template: template
      })

    %{
      id: :settings_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.settings"),
      forward_title: dgettext("eyra-project", "tabbar.item.settings.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :workflow,
         %{workflow: workflow},
         template,
         show_errors,
         %{
           current_user: user,
           uri_origin: uri_origin,
           timezone: timezone
         }
       ) do
    ready? = false

    %{
      id: :workflow_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-workflow", "tabbar.item.workflow"),
      forward_title: dgettext("eyra-workflow", "tabbar.item.workflow.forward"),
      type: :fullpage,
      live_component: Workflow.BuilderView,
      props: %{
        user: user,
        timezone: timezone,
        uri_origin: uri_origin,
        workflow: workflow,
        config: %{
          director: :assignment,
          list: %{
            title: dgettext("eyra-workflow", "item.list.title"),
            description: dgettext("eyra-workflow", "item.list.description")
          },
          library: Assignment.Template.workflow(template).library
        }
      }
    }
  end

  defp create_tab(
         :participants,
         assignment,
         template,
         show_errors,
         _assigns
       ) do
    %{
      id: :participants,
      ready: false,
      show_errors: show_errors,
      title: dgettext("eyra-assignment", "tabbar.item.participants"),
      forward_title: dgettext("eyra-assignment", "tabbar.item.participants.forward"),
      type: :fullpage,
      live_component: Assignment.ParticipantsView,
      props: %{
        assignment: assignment,
        template: template
      }
    }
  end

  defp create_tab(
         :monitor,
         assignment,
         _template,
         show_errors,
         %{fabric: fabric} = _assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :monitor, Assignment.MonitorView, %{
        number_widgets: number_widgets(assignment),
        progress_widgets: progress_widgets(assignment)
      })

    %{
      id: :monitor,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-assignment", "tabbar.item.monitor"),
      forward_title: dgettext("eyra-assignment", "tabbar.item.monitor.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp number_widgets(assignment) do
    [:started, :finished, :declined]
    |> Enum.map(&number_widget(&1, assignment))
  end

  defp number_widget(:started, assignment) do
    metric =
      Monitor.Public.event(assignment, :started)
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-assignment", "started.participants"),
      metric: metric,
      color: :primary
    }
  end

  defp number_widget(:finished, assignment) do
    metric =
      Monitor.Public.event(assignment, :finished)
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-assignment", "finished.participants"),
      metric: metric,
      color: :positive
    }
  end

  defp number_widget(:declined, assignment) do
    metric =
      Monitor.Public.event(assignment, :declined)
      |> Monitor.Public.unique()

    color =
      if metric > 0 do
        :negative
      else
        :primary
      end

    %{
      label: dgettext("eyra-assignment", "declined.participants"),
      metric: metric,
      color: color
    }
  end

  defp progress_widgets(%{workflow: workflow} = assignment) do
    Workflow.Public.list_items(workflow)
    |> Enum.map(&progress_widget(&1, assignment))
  end

  defp progress_widget(
         %Workflow.ItemModel{title: title, group: group} = item,
         %{info: %{subject_count: subject_count}} = assignment
       ) do
    started = Monitor.Public.unique(Monitor.Public.event(item, :started))
    finished = Monitor.Public.unique(Monitor.Public.event(item, :finished))

    subject_count =
      if subject_count do
        subject_count
      else
        0
      end

    current_amount =
      Monitor.Public.unique(Monitor.Public.event(assignment, :started)) -
        Monitor.Public.unique(Monitor.Public.event(assignment, :declined))

    expected_amount = max(subject_count, current_amount)

    %{
      label: "#{title} #{group}",
      target_amount: expected_amount,
      done_amount: finished,
      pending_amount: started - finished,
      done_label: dgettext("eyra-crew", "progress.finished.label"),
      pending_label: dgettext("eyra-crew", "progress.started.label"),
      target_label: dgettext("eyra-crew", "progress.remaining.label")
    }
  end
end
