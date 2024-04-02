defmodule Systems.Graphite.ContentPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Graphite
  }

  @tabs [:config, :invite, :submissions, :leaderboard]

  def view_model(
        %{id: id} = tool,
        assigns
      ) do
    show_errors = show_errors(tool, assigns)
    tabs = create_tabs(tool, show_errors, assigns)
    action_map = action_map(tool)
    actions = actions(tool, action_map)

    %{
      id: id,
      title: dgettext("eyra-benchmark", "content.title"),
      tabs: tabs,
      actions: actions,
      show_errors: show_errors
    }
  end

  defp show_errors(%{status: _status}, %{publish_clicked: _publish_clicked}) do
    # concept? = status == :concept
    # publish_clicked or not concept?
    false
  end

  defp action_map(%{id: id}) do
    preview_action = %{type: :http_get, to: "/graphite/#{id}", target: "_blank"}
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
            label: dgettext("eyra-benchmark", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-benchmark", "preview.button")}
        }
      },
      publish: %{
        label: %{
          action: publish_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-benchmark", "publish.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: publish_action,
          face: %{type: :icon, icon: :publish, alt: dgettext("eyra-benchmark", "publish.button")}
        },
        handle_click: &handle_publish/1
      },
      retract: %{
        label: %{
          action: retract_action,
          face: %{
            type: :secondary,
            label: dgettext("eyra-benchmark", "retract.button"),
            text_color: "text-error",
            border_color: "border-error"
          }
        },
        icon: %{
          action: retract_action,
          face: %{type: :icon, icon: :retract, alt: dgettext("eyra-benchmark", "retract.button")}
        },
        handle_click: &handle_retract/1
      },
      close: %{
        label: %{
          action: close_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-benchmark", "close.button")
          }
        },
        icon: %{
          action: close_action,
          face: %{type: :icon, icon: :close, alt: dgettext("eyra-benchmark", "close.button")}
        },
        handle_click: &handle_close/1
      },
      open: %{
        label: %{
          action: open_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-benchmark", "open.button")
          }
        },
        icon: %{
          action: open_action,
          face: %{type: :icon, icon: :open, alt: dgettext("eyra-benchmark", "open.button")}
        },
        handle_click: &handle_open/1
      }
    }
  end

  defp actions(%{status: :concept}, %{publish: publish, preview: preview}),
    do: [publish: publish, preview: preview]

  defp actions(%{status: :online}, %{retract: retract}), do: [retract: retract]

  defp actions(%{status: :offline}, %{publish: publish, close: close}),
    do: [publish: publish, close: close]

  defp actions(%{status: :idle}, %{open: open}), do: [open: open]

  defp handle_publish(socket) do
    socket |> set_tool_status(:online)
  end

  defp handle_retract(socket) do
    socket |> set_tool_status(:offline)
  end

  defp handle_close(socket) do
    socket |> set_tool_status(:idle)
  end

  defp handle_open(socket) do
    socket |> set_tool_status(:concept)
  end

  defp set_tool_status(%{assigns: %{vm: %{id: id}}} = socket, status) do
    Graphite.Public.set_tool_status(id, status)
    socket
  end

  defp create_tabs(tool, show_errors, assigns) do
    Enum.map(@tabs, &create_tab(&1, tool, show_errors, assigns))
  end

  defp create_tab(
         :config,
         tool,
         show_errors,
         _assigns
       ) do
    ready? = false

    %{
      id: :config_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.config"),
      forward_title: dgettext("eyra-project", "tabbar.item.config.forward"),
      type: :fullpage,
      live_component: Graphite.ToolForm,
      props: %{
        entity: tool
      }
    }
  end

  defp create_tab(
         :submissions,
         tool,
         show_errors,
         _assigns
       ) do
    ready? = false

    %{
      id: :submissions,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-benchmark", "tabbar.item.submissions"),
      forward_title: dgettext("eyra-benchmark", "tabbar.item.submissions.forward"),
      type: :fullpage,
      live_component: Graphite.SubmissionOverview,
      props: %{
        entity: tool
      }
    }
  end

  defp create_tab(
         :leaderboard,
         tool,
         show_errors,
         _assigns
       ) do
    ready? = false

    %{
      id: :leaderboard,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-benchmark", "tabbar.item.leaderboard"),
      forward_title: dgettext("eyra-benchmark", "tabbar.item.leaderboard.forward"),
      type: :fullpage,
      live_component: Graphite.Leaderboard.Overview,
      props: %{
        entity: tool
      }
    }
  end
end
