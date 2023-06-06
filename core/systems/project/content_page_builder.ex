defmodule Systems.Project.ContentPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Project,
    Sequence,
    Privacy
  }

  def view_model(
        %{
          id: id
        } = project,
        %{
          current_user: user,
          uri_path: _uri_path,
          uri_origin: uri_origin,
          submit_clicked: submit_clicked,
          locale: locale
        }
      ) do
    submitted? = false

    show_errors = submit_clicked or submitted?
    tabs = create_tabs(project, show_errors, user, uri_origin, locale)

    %{
      id: id,
      tabs: tabs,
      show_errors: show_errors,
      preview_path: "/"
    }
  end

  defp create_tabs(project, show_errors, user, uri_origin, locale) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, project, show_errors, user, uri_origin, locale))
  end

  defp get_tab_keys() do
    [:config, :tasks, :privacy, :invite, :monitor]
  end

  defp create_tab(
         :config,
         project,
         show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    ready? = false

    %{
      id: :config_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.config"),
      forward_title: dgettext("eyra-project", "tabbar.item.config.forward"),
      type: :fullpage,
      live_component: Project.ConfigForm,
      props: %{
        entity: project
      }
    }
  end

  defp create_tab(
         :tasks,
         _project,
         show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    ready? = false

    %{
      id: :tasks_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.tasks"),
      forward_title: dgettext("eyra-project", "tabbar.item.tasks.forward"),
      type: :fullpage,
      live_component: Sequence.BuilderView,
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
         _project,
         show_errors,
         _user,
         _uri_origin,
         _locale
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
         project,
         show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    ready? = false

    %{
      id: :invite_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-project", "tabbar.item.invite"),
      forward_title: dgettext("eyra-project", "tabbar.item.invite.forward"),
      type: :fullpage,
      live_component: Project.InviteForm,
      props: %{
        entity: project
      }
    }
  end

  defp create_tab(
         :monitor,
         project,
         _show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    %{
      id: :monitor,
      title: dgettext("eyra-project", "tabbar.item.monitor"),
      forward_title: dgettext("eyra-project", "tabbar.item.monitor.forward"),
      type: :fullpage,
      live_component: Project.MonitorView,
      props: %{
        entity: project
      }
    }
  end
end
