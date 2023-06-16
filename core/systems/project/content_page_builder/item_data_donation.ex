defmodule Systems.Project.ContentPageBuilder.ItemDataDonation do
  import CoreWeb.Gettext

  alias Systems.{
    Project,
    DataDonation,
    Privacy
  }

  def view_model(
        %{
          id: id,
          tool_ref: %{
            data_donation_tool: tool
          }
        } = item,
        assigns
      ) do
    show_errors = show_errors(tool, assigns)
    tabs = create_tabs(item, show_errors, assigns)
    action_map = action_map(tool)
    actions = actions(tool, action_map)

    %{
      id: id,
      title: dgettext("eyra-data-donation", "content.title"),
      tabs: tabs,
      actions: actions,
      show_errors: show_errors
    }
  end

  defp show_errors(%{status: status}, %{publish_clicked: publish_clicked}) do
    concept? = status == :concept
    publish_clicked or not concept?
  end

  defp action_map(%{id: tool_id}) do
    %{
      preview: %{
        action: %{type: :http_get, to: "/data-donation/#{tool_id}", target: "_blank"}
      },
      publish: %{
        action: %{type: :send, event: "action_click", item: :publish},
        handle_click: &handle_publish/1
      },
      retract: %{
        action: %{type: :send, event: "action_click", item: :retract},
        handle_click: &handle_retract/1
      },
      close: %{
        action: %{type: :send, event: "action_click", item: :close},
        handle_click: &handle_close/1
      },
      open: %{
        action: %{type: :send, event: "action_click", item: :open},
        handle_click: &handle_open/1
      }
    }
  end

  defp actions(%{status: :concept}, %{publish: publish, preview: preview}), do: [publish, preview]
  defp actions(%{status: :online}, %{retract: retract}), do: [retract]
  defp actions(%{status: :offline}, %{publish: publish, close: close}), do: [publish, close]
  defp actions(%{status: :idle}, %{open: open}), do: [open]

  defp handle_publish(socket) do
    socket
  end

  defp handle_retract(socket) do
    socket
  end

  defp handle_close(socket) do
    socket
  end

  defp handle_open(socket) do
    socket
  end

  defp create_tabs(item, show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, item, show_errors, assigns))
  end

  defp get_tab_keys() do
    [:config, :tasks, :privacy, :invite, :monitor]
  end

  defp create_tab(
         :config,
         %{tool_ref: %{data_donation_tool_id: tool_id}} = item,
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
      live_component: Project.ItemConfigForm,
      props: %{
        entity: item,
        sub_form: %{
          id: :tool_form,
          module: DataDonation.ToolForm,
          entity_id: tool_id
        }
      }
    }
  end

  defp create_tab(
         :tasks,
         _item,
         show_errors,
         _assigns
       ) do
    ready? = false

    %{
      id: :tasks_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.tasks"),
      forward_title: dgettext("eyra-project", "tabbar.item.tasks.forward"),
      type: :fullpage,
      live_component: DataDonation.TaskBuilderView,
      props: %{
        entity: nil,
        flow: %{
          title: "Task list",
          description:
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        },
        library: %{
          title: "Task library",
          description:
            "Overview of tasks available to add to your flow lorem ipsum dolor sit amet.",
          items: [
            %{
              id: :request,
              title: "Request DDP",
              description: "Description of the task lorem ipsum dolor sit amet. "
            },
            %{
              id: :download,
              title: "Download DDP",
              description: "Description of the task lorem ipsum dolor sit amet. "
            },
            %{
              id: :donate,
              title: "Donate",
              description: "Description of the task lorem ipsum dolor sit amet. "
            },
            %{
              id: :survey,
              title: "Survey",
              description: "Description of the task lorem ipsum dolor sit amet. "
            }
          ]
        }
      }
    }
  end

  defp create_tab(
         :privacy,
         _item,
         show_errors,
         _assigns
       ) do
    ready? = false

    %{
      id: :privacy_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.privacy"),
      forward_title: dgettext("eyra-project", "tabbar.item.privacy.forward"),
      type: :fullpage,
      live_component: Privacy.Form,
      props: %{
        entity: %{}
      }
    }
  end

  defp create_tab(
         :invite,
         %{tool_ref: %{data_donation_tool: %{id: tool_id}}},
         show_errors,
         %{uri_origin: uri_origin}
       ) do
    ready? = false
    url = uri_origin <> "/data-donation/#{tool_id}"

    %{
      id: :invite_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.invite"),
      forward_title: dgettext("eyra-project", "tabbar.item.invite.forward"),
      type: :fullpage,
      live_component: Project.InviteForm,
      props: %{
        url: url
      }
    }
  end

  defp create_tab(
         :monitor,
         item,
         _show_errors,
         _assigns
       ) do
    %{
      id: :monitor,
      title: dgettext("eyra-project", "tabbar.item.monitor"),
      forward_title: dgettext("eyra-project", "tabbar.item.monitor.forward"),
      type: :fullpage,
      live_component: Project.ItemMonitorView,
      props: %{
        entity: item
      }
    }
  end
end
