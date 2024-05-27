defmodule Systems.Advert.ContentPageBuilder do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  alias Systems.Advert
  alias Systems.Pool
  alias Systems.Monitor

  def view_model(
        %{
          id: advert_id,
          submission: submission,
          promotion: promotion
        } = advert,
        assigns
      ) do
    submitted? = Pool.SubmissionModel.submitted?(submission)
    show_errors = submitted?

    tabs = create_tabs(advert, show_errors, assigns)
    action_map = action_map(advert, assigns)
    actions = actions(advert, action_map)

    %{
      title: dgettext("link-advert", "content.title"),
      id: advert_id,
      submission: submission,
      promotion: promotion,
      tabs: tabs,
      actions: actions,
      submitted?: submitted?,
      show_errors: show_errors,
      active_menu_item: :projects
    }
  end

  defp create_tabs(advert, show_errors, assigns) do
    advert
    |> get_tab_keys()
    |> Enum.map(&create_tab(&1, advert, show_errors, assigns))
  end

  defp get_tab_keys(%{submission: %{pool: %{currency: %{type: :legal}}}}) do
    [:settings, :pool, :monitor]
  end

  defp get_tab_keys(_advert) do
    [:settings, :pool, :monitor]
  end

  defp create_tab(
         :settings,
         advert,
         show_errors,
         %{fabric: fabric}
       ) do
    child =
      Fabric.prepare_child(fabric, :promotion_form, Advert.SettingsView, %{
        advert: advert
      })

    %{
      id: :settings,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.settings"),
      forward_title: dgettext("link-advert", "tabbar.item.settings.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :pool,
         %{submission: submission},
         show_errors,
         %{fabric: fabric, current_user: user}
       ) do
    child =
      Fabric.prepare_child(fabric, :submission_form, Advert.SubmissionView, %{
        entity: submission,
        user: user
      })

    %{
      id: :pool,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.pool"),
      forward_title: dgettext("link-advert", "tabbar.item.pool.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :funding,
         %{assignment: assignment, submission: submission},
         show_errors,
         %{fabric: fabric, current_user: user}
       ) do
    child =
      Fabric.prepare_child(fabric, :funding, Advert.FundingView, %{
        assignment: assignment,
        submission: submission,
        budget: nil,
        user: user
      })

    %{
      id: :funding,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.funding"),
      forward_title: dgettext("link-advert", "tabbar.item.funding.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :monitor,
         advert,
         show_errors,
         %{fabric: fabric}
       ) do
    child =
      Fabric.prepare_child(fabric, :monitor, Advert.MonitorView, %{
        number_widgets: number_widgets(advert)
      })

    %{
      id: :monitor,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.monitor"),
      forward_title: dgettext("link-advert", "tabbar.item.monitor.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp action_map(%{promotion: %{id: promotion_id}}, _) do
    preview_action = %{type: :http_get, to: ~p"/promotion/#{promotion_id}", target: "_blank"}
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
            label: dgettext("eyra-advert", "preview.button"),
            bg_color: "bg-primary"
          }
        },
        icon: %{
          action: preview_action,
          face: %{type: :icon, icon: :preview, alt: dgettext("eyra-advert", "preview.button")}
        }
      },
      publish: %{
        label: %{
          action: publish_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-advert", "publish.button"),
            bg_color: "bg-success"
          }
        },
        icon: %{
          action: publish_action,
          face: %{type: :icon, icon: :publish, alt: dgettext("eyra-advert", "preview.button")}
        },
        handle_click: &handle_publish/1
      },
      retract: %{
        label: %{
          action: retract_action,
          face: %{
            type: :secondary,
            label: dgettext("eyra-advert", "retract.button"),
            text_color: "text-error",
            border_color: "border-error"
          }
        },
        icon: %{
          action: retract_action,
          face: %{
            type: :icon,
            icon: :retract,
            alt: dgettext("eyra-advert", "retract.button")
          }
        },
        handle_click: &handle_retract/1
      },
      close: %{
        label: %{
          action: close_action,
          face: %{
            type: :primary,
            label: dgettext("eyra-advert", "close.button")
          }
        },
        icon: %{
          action: close_action,
          face: %{type: :icon, icon: :close, alt: dgettext("eyra-advert", "close.button")}
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

  defp set_status(%{assigns: %{model: advert}} = socket, status) do
    {:ok, advert} = Advert.Public.update(advert, %{status: status})
    socket |> Phoenix.Component.assign(model: advert)
  end

  defp number_widgets(advert) do
    [:visited, :applied, :bounce_rate]
    |> Enum.map(&number_widget(&1, advert))
  end

  defp number_widget(:visited, advert) do
    metric =
      Monitor.Public.event(advert, :visited)
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-advert", "visited.participants"),
      metric: metric,
      color: :primary
    }
  end

  defp number_widget(:applied, advert) do
    metric =
      Monitor.Public.event(advert, :applied)
      |> Monitor.Public.unique()

    %{
      label: dgettext("eyra-advert", "applied.participants"),
      metric: metric,
      color: :positive
    }
  end

  defp number_widget(:bounce_rate, advert) do
    visited =
      Monitor.Public.event(advert, :visited)
      |> Monitor.Public.unique()

    applied =
      Monitor.Public.event(advert, :applied)
      |> Monitor.Public.unique()

    metric =
      if visited > 0 do
        visited / (visited - applied) * 100
      else
        0
      end

    %{
      label: dgettext("eyra-advert", "bounce.rate"),
      metric: metric,
      color: :negative
    }
  end
end
