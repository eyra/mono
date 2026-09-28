defmodule Systems.Feldspar.ToolViewBuilder do
  use Gettext, backend: CoreWeb.Gettext
  use CoreWeb, :verified_routes

  @doc """
  Builds view model for Feldspar tool view.

  ## Parameters
  - tool: The Feldspar tool model
  - assigns: Contains title and icon from CrewTaskContext
  """
  def view_model(tool, %{title: title, icon: icon} = assigns) do
    {app_view, error} = build_app_view(tool, assigns)
    loading = Map.get(assigns, :loading, false) or Map.get(assigns, :preparing, false)
    recovery? = Map.get(assigns, :recovery, false)
    completed? = Map.get(assigns, :task_status) in Systems.Crew.TaskStatus.finished_states()

    %{
      tool: tool,
      title: title,
      icon: normalize_icon(icon),
      description: description(recovery?, completed?),
      recovery?: recovery? and not completed?,
      completed?: completed?,
      recovery_id: "feldspar-recovery-#{tool.id}-#{Map.get(assigns, :task_id)}",
      recovery_scope: recovery_scope(assigns),
      support_button: support_button(assigns),
      button: build_button(loading, recovery?, completed?, assigns),
      app_view: app_view,
      error: error
    }
  end

  defp description(_, true), do: dgettext("eyra-feldspar", "recovery.completed")
  defp description(true, false), do: dgettext("eyra-feldspar", "recovery.description")
  defp description(false, false), do: dgettext("eyra-feldspar", "tool.description")

  defp recovery_scope(%{
         current_user: %{id: user_id},
         assignment_id: assignment_id,
         task_id: task_id
       })
       when is_integer(user_id) and is_integer(assignment_id) and is_integer(task_id),
       do: "#{user_id}:#{assignment_id}:#{task_id}"

  defp recovery_scope(_), do: nil

  defp support_button(assigns) do
    params =
      Map.take(assigns, [:assignment_id, :task_id])
      |> Enum.filter(fn {_key, value} -> is_integer(value) end)
      |> Map.new()
      |> Map.put(:context, "feldspar_recovery")

    %{
      action: %{type: :http_get, to: ~p"/support/helpdesk?#{params}"},
      face: %{type: :secondary, label: dgettext("eyra-feldspar", "recovery.support")},
      testid: "feldspar-recovery-support"
    }
  end

  defp build_button(loading, recovery?, completed?, assigns) do
    %{
      action: %{type: :send, event: "prepare_start"},
      face: %{
        type: :primary,
        label:
          if(recovery?,
            do: dgettext("eyra-feldspar", "recovery.retry"),
            else: dgettext("eyra-feldspar", "tool.button")
          ),
        loading: loading
      },
      enabled?: Map.get(assigns, :recovery_checked, false) and not loading and not completed?,
      testid: "feldspar-start"
    }
  end

  defp build_app_view(%{archive_ref: nil}, _assigns) do
    {nil, dgettext("eyra-feldspar", "tool.archive.not.configured")}
  end

  defp build_app_view(%{id: id, archive_ref: archive_ref}, assigns) do
    {LiveNest.Element.prepare_live_component(
       "feldspar_app_view_#{id}",
       Systems.Feldspar.AppView,
       key: "feldspar_tool_#{id}",
       url: archive_ref <> "/index.html",
       locale: Gettext.get_locale(CoreWeb.Gettext),
       attempt_id: Map.get(assigns, :attempt_id),
       upload_context: build_upload_context(assigns)
     ), nil}
  end

  defp build_upload_context(assigns) do
    %{
      assignment_id: Map.get(assigns, :assignment_id),
      task: Map.get(assigns, :workflow_item_id),
      participant: Map.get(assigns, :participant),
      group: normalize_icon(Map.get(assigns, :icon)),
      panel_info: Map.get(assigns, :panel_info)
    }
  end

  defp normalize_icon(nil), do: nil
  defp normalize_icon(icon) when is_binary(icon), do: String.downcase(icon)
  defp normalize_icon(icon) when is_atom(icon), do: icon |> Atom.to_string() |> String.downcase()
end
