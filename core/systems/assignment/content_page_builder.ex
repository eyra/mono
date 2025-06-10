defmodule Systems.Assignment.ContentPageBuilder do
  use CoreWeb, :verified_routes
  require Logger
  use Systems.Content.PageBuilder

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept
  alias Systems.Assignment
  alias Systems.Content
  alias Systems.Monitor
  alias Systems.Project
  alias Systems.Workflow
  alias Systems.Zircon

  @moduledoc """
    Assignment is a generic concept with a template pattern. The content page is therefor rendered with optional components.
    This builder module supports several specials with each a specific View Model.
    For a full overview of the template feature see `Systems.Assignment.Template`.
  """

  @doc """
    Returns a view model based on the templates defined in:
    * Paper Screening: `Systems.Assignment.TemplatePaperScreening`
    * Benchmark Challenge: `Systems.Assignment.TemplateBenchmarkChallenge`
    * Data Donation: `Systems.Assignment.TemplateDataDonation`
    * Questionnaire: `Systems.Assignment.TemplateQuestionnaire`
  """
  def view_model(
        %{id: id} = assignment,
        %{branch: branch} = assigns
      ) do
    show_errors = false
    template = Assignment.Private.get_template(assignment)
    breadcrumbs = Concept.Branch.hierarchy(branch)
    tabs = create_tabs(assignment, template, show_errors, assigns)
    action_map = action_map(assignment)
    actions = actions(assignment, action_map)

    %{
      id: id,
      title: Assignment.Template.title(template),
      breadcrumbs: breadcrumbs,
      tabs: tabs,
      actions: actions,
      show_errors: show_errors,
      active_menu_item: :projects
    }
  end

  defp action_map(assignment) do
    preview_url = Assignment.Private.get_preview_url(assignment)

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

  @impl true
  def set_status(%{assigns: %{model: assignment}} = socket, status) do
    {:ok, assignment} = Assignment.Public.update(assignment, %{status: status})
    socket |> Phoenix.Component.assign(model: assignment)
  end

  defp create_tabs(
         assignment,
         template,
         show_errors,
         %{uri_origin: _, viewport: _, breakpoint: _} = assigns
       ) do
    workflow_config = Assignment.Template.workflow_config(template)

    template
    |> Assignment.Template.tabs()
    |> Enum.map(fn {tab_key, tab_config} ->
      create_tab(tab_key, assignment, tab_config, workflow_config, show_errors, assigns)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp create_tabs(_assignment, _template, _show_errors, _assigns) do
    []
  end

  defp create_tab(_, _, nil, _, _, _), do: nil

  defp create_tab(
         :settings,
         assignment,
         {title, content_flags},
         _workflow_config,
         show_errors,
         %{fabric: fabric, uri_origin: uri_origin, viewport: viewport, breakpoint: breakpoint} =
           _assigns
       ) do
    ready? = false

    project_node =
      assignment
      |> Project.Public.get_item_by()
      |> Project.Public.get_node_by_item!()

    project_item =
      project_node
      |> Project.Public.list_items(:storage_endpoint, Project.ItemModel.preload_graph(:down))
      |> List.first()

    storage_endpoint =
      if project_item do
        Map.get(project_item, :storage_endpoint)
      else
        nil
      end

    child =
      Fabric.prepare_child(fabric, :settings_form, Assignment.SettingsView, %{
        entity: assignment,
        project_node: project_node,
        storage_endpoint: storage_endpoint,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint,
        title: title,
        content_flags: content_flags
      })

    %{
      id: :settings_form,
      ready: ready?,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:workflow, _, _, %{singleton?: true}, _, _) do
    raise "Workflow tab is not supported for singleton workflows. Please provide alternative tab(s) for manipulating the workflow. See :import and :criteria tabs for examples."
  end

  defp create_tab(
         :workflow,
         %{workflow: workflow},
         {title, content_flags},
         workflow_config,
         show_errors,
         %{
           fabric: fabric,
           current_user: user,
           uri_origin: uri_origin,
           timezone: timezone
         }
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :system, Workflow.BuilderView, %{
        user: user,
        timezone: timezone,
        uri_origin: uri_origin,
        workflow: workflow,
        workflow_config: workflow_config,
        title: title,
        description: dgettext("eyra-workflow", "item.list.description"),
        director: :assignment,
        content_flags: content_flags
      })

    %{
      id: :workflow_form,
      ready: ready?,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:affiliate, %{affiliate: nil} = _assignment, _, _, _, _), do: nil

  defp create_tab(:affiliate, assignment, {title, content_flags}, _, show_errors, %{
         fabric: fabric
       }) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :affiliate, Assignment.AffiliateView, %{
        assignment: assignment,
        title: title,
        content_flags: content_flags
      })

    %{
      id: :affiliate,
      ready: ready?,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :import,
         %{
           workflow: %{
             items: [%{tool_ref: %{zircon_screening_tool: %{} = zircon_screening_tool}}]
           }
         },
         {title, content_flags},
         _workflow_config,
         show_errors,
         %{fabric: fabric, current_user: user, timezone: timezone}
       ) do
    child =
      Fabric.prepare_child(fabric, :system, Zircon.Screening.ImportView, %{
        tool: zircon_screening_tool,
        timezone: timezone,
        user: user,
        title: title,
        content_flags: content_flags
      })

    %{
      id: :import,
      ready: false,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:import, _, _, _, _, _) do
    raise "Import tab is only supported for singleton workflows with one Zircon tool"
  end

  defp create_tab(
         :criteria,
         %{
           workflow: %{
             items: [%{tool_ref: %{zircon_screening_tool: %{} = zircon_screening_tool}}]
           }
         },
         {title, content_flags},
         _workflow_config,
         show_errors,
         %{fabric: fabric, current_user: user}
       ) do
    child =
      Fabric.prepare_child(fabric, :system, Zircon.CriteriaView, %{
        tool: zircon_screening_tool,
        user: user,
        title: title,
        content_flags: content_flags
      })

    %{
      id: :criteria,
      ready: false,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:criteria, _, _, _, _, _) do
    raise "Criteria tab is only supported for singleton workflows with one Zircon tool"
  end

  defp create_tab(
         :participants,
         assignment,
         {title, content_flags},
         _workflow_config,
         show_errors,
         %{fabric: fabric, current_user: user}
       ) do
    child =
      Fabric.prepare_child(fabric, :system, Assignment.ParticipantsView, %{
        assignment: assignment,
        user: user,
        title: title,
        content_flags: content_flags
      })

    %{
      id: :participants,
      ready: false,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :monitor,
         assignment,
         {title, content_flags},
         _workflow_config,
         show_errors,
         %{fabric: fabric} = _assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :monitor, Assignment.MonitorView, %{
        assignment: assignment,
        number_widgets: number_widgets(assignment),
        progress_widgets: progress_widgets(assignment),
        title: title,
        content_flags: content_flags
      })

    %{
      id: :monitor,
      ready: ready?,
      show_errors: show_errors,
      title: title,
      forward_title: dgettext("eyra-ui", "tabbar.item.forward", to: title),
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
      Monitor.Public.event({assignment, :started})
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-assignment", "started.participants"),
      metric: metric,
      color: :primary
    }
  end

  defp number_widget(:finished, assignment) do
    metric =
      Monitor.Public.event({assignment, :finished})
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-assignment", "finished.participants"),
      metric: metric,
      color: :positive
    }
  end

  defp number_widget(:declined, assignment) do
    metric =
      Monitor.Public.event({assignment, :declined})
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
    started = Monitor.Public.unique(Monitor.Public.event({item, :started}))
    finished = Monitor.Public.unique(Monitor.Public.event({item, :finished}))

    subject_count =
      if subject_count do
        subject_count
      else
        0
      end

    current_amount =
      Monitor.Public.unique(Monitor.Public.event({assignment, :started})) -
        Monitor.Public.unique(Monitor.Public.event({assignment, :declined}))

    expected_amount = max(subject_count, current_amount)
    pending_amount = max(0, started - finished)

    %{
      label: "#{title} #{group}",
      target_amount: expected_amount,
      done_amount: finished,
      pending_amount: pending_amount,
      done_label: dgettext("eyra-crew", "progress.finished.label"),
      pending_label: dgettext("eyra-crew", "progress.started.label"),
      target_label: dgettext("eyra-crew", "progress.remaining.label")
    }
  end
end
