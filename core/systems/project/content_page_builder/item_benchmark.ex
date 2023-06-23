defmodule Systems.Project.ContentPageBuilder.ItemBenchmark do
  import CoreWeb.Gettext

  alias Systems.{
    Project,
    Benchmark
  }

  @tabs [:config, :invite, :submissions, :leaderboard]

  def view_model(
        %{
          id: id,
          tool_ref: %{
            benchmark_tool: tool
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
      tool_id: tool.id,
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

  defp action_map(%{id: tool_id}) do
    %{
      preview: %{
        action: %{type: :http_get, to: "/benchmark/#{tool_id}", target: "_blank"}
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

  defp set_tool_status(%{assigns: %{vm: %{tool_id: tool_id}}} = socket, status) do
    Benchmark.Public.set_tool_status(tool_id, status)
    socket
  end

  defp create_tabs(item, show_errors, assigns) do
    Enum.map(@tabs, &create_tab(&1, item, show_errors, assigns))
  end

  defp create_tab(
         :config,
         %{tool_ref: %{benchmark_tool: %{id: _} = tool}} = item,
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
          module: Benchmark.ToolForm,
          entity: tool
        }
      }
    }
  end

  defp create_tab(
         :submissions,
         %{tool_ref: %{benchmark_tool: benchmark_tool}},
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
      live_component: Benchmark.SubmissionOverview,
      props: %{
        entity: benchmark_tool
      }
    }
  end

  defp create_tab(
         :leaderboard,
         %{tool_ref: %{benchmark_tool: benchmark_tool}},
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
      live_component: Benchmark.LeaderboardOverview,
      props: %{
        entity: benchmark_tool
      }
    }
  end

  defp create_tab(
         :invite,
         %{tool_ref: %{benchmark_tool: %{id: tool_id}}},
         show_errors,
         %{uri_origin: uri_origin}
       ) do
    ready? = false
    url = uri_origin <> "/benchmark/#{tool_id}"

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
end
