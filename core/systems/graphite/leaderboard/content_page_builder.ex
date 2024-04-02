defmodule Systems.Graphite.Leaderboard.ContentPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias Systems.Graphite
  alias Systems.Graphite.Leaderboard

  def view_model(%{id: id, name: name} = leaderboard, assigns) do
    action_map = action_map(leaderboard, assigns)

    %{
      id: id,
      title: name,
      tabs: create_tabs(leaderboard, false, assigns),
      actions: actions(leaderboard, action_map),
      show_errors: false,
      default_tab: :config
    }
  end

  defp action_map(leaderboard, %{current_user: %{id: user_id}}) do
    preview_url = Graphite.Leaderboard.Private.get_preview_url(leaderboard)

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
            alt: dgettext("eyra-benchmark", "assignment.button")
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

  # FIXME JAN: add relevant actions
  # They need to be made specific of what has already been done to the leaderboard
  # defp actions(_, %{open: open}), do: [open: open]
  # defp actions(_, %{publish: publish, preview: preview}), do: [publish: publish, preview: preview]

  defp actions(_leaderboard, %{preview: preview, publish: publish}) do
    [preview: preview, publish: publish]
  end

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

  # FIXME: somethign goes wrong here, don't know why
  defp set_status(%{assigns: %{model: leaderboard}} = socket, status) do
    {:ok, leaderboard} = Graphite.Public.update(leaderboard, %{status: status})
    socket |> Phoenix.Component.assign(model: leaderboard)
  end

  defp create_tabs(leaderboard, show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, leaderboard, show_errors, assigns))
  end

  defp get_tab_keys() do
    [:config, :upload]
  end

  defp create_tab(:config, leaderboard, show_errors, assigns) do
    %{fabric: fabric, uri_origin: uri_origin, viewport: viewport, breakpoint: breakpoint} =
      assigns

    child =
      Fabric.prepare_child(fabric, :settings_form, Graphite.Leaderboard.SettingsView, %{
        entity: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      })

    %{
      id: :settings_form,
      ready: false,
      show_errors: show_errors,
      title: "Settings",
      forward_title: "",
      backward_title: "Change settings",
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:upload, leaderboard, show_errors, assigns) do
    %{fabric: fabric, uri_origin: uri_origin, viewport: viewport, breakpoint: breakpoint} =
      assigns

    child =
      Fabric.prepare_child(fabric, :upload_form, Graphite.Leaderboard.UploadView, %{
        entity: leaderboard,
        uri_origin: uri_origin,
        viewport: viewport,
        breakpoint: breakpoint
      })

    %{
      id: :upload_form,
      ready: false,
      show_errors: show_errors,
      title: "Upload Scores",
      forward_title: "Upload scores",
      type: :fullpage,
      child: child
    }
  end
end
