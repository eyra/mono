defmodule Systems.Advert.ContentPageBuilder do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  alias Systems.{
    Advert,
    Assignment,
    Promotion,
    Pool
  }

  require Advert.Themes
  alias Advert.Themes

  def view_model(
        %{
          id: advert_id,
          submission: submission,
          promotion:
            %{
              id: promotion_id
            } = promotion
        } = advert,
        assigns
      ) do
    submitted? = Pool.SubmissionModel.submitted?(submission)
    show_errors = submitted?

    tabs = create_tabs(advert, show_errors, assigns)
    preview_path = ~p"/promotion/#{promotion_id}?preview=true"

    %{
      title: dgettext("link-advert", "content.title"),
      id: advert_id,
      submission: submission,
      promotion: promotion,
      tabs: tabs,
      actions: [],
      submitted?: submitted?,
      show_errors: show_errors,
      preview_path: preview_path,
      active_menu_item: :projects
    }
  end

  defp create_tabs(advert, show_errors, assigns) do
    advert
    |> get_tab_keys()
    |> Enum.map(&create_tab(&1, advert, show_errors, assigns))
  end

  defp get_tab_keys(%{submission: %{pool: %{currency: %{type: :legal}}}}) do
    [:promotion, :submission, :monitor]
  end

  defp get_tab_keys(_advert) do
    [:promotion, :submission, :monitor]
  end

  defp create_tab(
         :promotion,
         %{promotion: promotion},
         show_errors,
         %{fabric: fabric}
       ) do
    ready? = Promotion.Public.ready?(promotion)

    child =
      Fabric.prepare_child(fabric, :promotion_form, Promotion.FormView, %{
        entity: promotion,
        themes_module: Themes
      })

    %{
      id: :promotion_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.promotion"),
      forward_title: dgettext("link-advert", "tabbar.item.promotion.forward"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :submission,
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
      id: :submission_form,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.submission"),
      forward_title: dgettext("link-advert", "tabbar.item.submission.forward"),
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
         %{assignment: assignment} = advert,
         show_errors,
         %{fabric: fabric}
       ) do
    attention_list_enabled? = Assignment.Public.attention_list_enabled?(assignment)
    task_labels = Assignment.Public.task_labels(assignment)

    child =
      Fabric.prepare_child(fabric, :monitor, Advert.MonitorView, %{
        entity: advert,
        attention_list_enabled?: attention_list_enabled?,
        labels: task_labels
      })

    %{
      id: :funding,
      ready: true,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.monitor"),
      forward_title: dgettext("link-advert", "tabbar.item.monitor.forward"),
      type: :fullpage,
      child: child
    }
  end
end
