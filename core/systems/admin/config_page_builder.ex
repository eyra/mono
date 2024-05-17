defmodule Systems.Admin.ConfigPageBuilder do
  import CoreWeb.Gettext

  def view_model(%{id: :singleton}, assigns) do
    %{
      tabs: create_tabs(false, assigns),
      show_errors: false
    }
  end

  defp create_tabs(show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, show_errors, assigns))
  end

  defp get_tab_keys() do
    [:system, :org, :actions]
  end

  defp create_tab(
         :system,
         show_errors,
         %{fabric: fabric, locale: locale, current_user: user}
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :system, Systems.Admin.SystemView, %{
        locale: locale,
        user: user
      })

    %{
      id: :system,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "system.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :org,
         show_errors,
         %{fabric: fabric, locale: locale}
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :org, Systems.Admin.OrgView, %{
        locale: locale
      })

    %{
      id: :org,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "org.content.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :actions,
         show_errors,
         %{fabric: fabric}
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :org, Systems.Admin.ActionsView, %{
        tickets: []
      })

    %{
      id: :org,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "actions.title"),
      type: :fullpage,
      child: child
    }
  end
end
