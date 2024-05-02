defmodule Systems.Advert.Builders.AdvertContentPage do
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
        %{
          current_user: user,
          uri_path: uri_path,
          uri_origin: uri_origin,
          submit_clicked: submit_clicked,
          locale: locale
        }
      ) do
    submitted? = Pool.SubmissionModel.submitted?(submission)
    show_errors = submit_clicked or submitted?

    tabs = create_tabs(advert, show_errors, user, uri_origin, locale)
    preview_path = ~p"/promotion/#{promotion_id}?preview=true&back=#{uri_path}"

    %{
      title: dgettext("link-advert", "content.title"),
      id: advert_id,
      submission: submission,
      promotion: promotion,
      tabs: tabs,
      submitted?: submitted?,
      show_errors: show_errors,
      preview_path: preview_path
    }
  end

  defp create_tabs(advert, show_errors, user, uri_origin, locale) do
    advert
    |> get_tab_keys()
    |> Enum.map(&create_tab(&1, advert, show_errors, user, uri_origin, locale))
  end

  defp get_tab_keys(%{submission: %{pool: %{currency: %{type: :legal}}}}) do
    [:promotion, :assignment, :funding, :submission, :monitor]
  end

  defp get_tab_keys(_advert) do
    [:promotion, :assignment, :submission, :monitor]
  end

  defp create_tab(
         :promotion,
         %{promotion: promotion},
         show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    ready? = Promotion.Public.ready?(promotion)

    %{
      id: :promotion_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.promotion"),
      forward_title: dgettext("link-advert", "tabbar.item.promotion.forward"),
      type: :fullpage,
      live_component: Promotion.FormView,
      props: %{
        entity: promotion,
        themes_module: Themes
      }
    }
  end

  defp create_tab(
         :assignment,
         %{assignment: assignment},
         show_errors,
         user,
         uri_origin,
         _locale
       ) do
    ready? = Assignment.Public.ready?(assignment)

    %{
      id: :assignment_form,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("link-advert", "tabbar.item.assignment"),
      forward_title: dgettext("link-advert", "tabbar.item.assignment.forward"),
      type: :fullpage,
      live_component: Assignment.AssignmentForm,
      props: %{
        entity: assignment,
        uri_origin: uri_origin,
        user: user,
        target: self()
      }
    }
  end

  defp create_tab(
         :submission,
         %{submission: submission},
         _show_errors,
         user,
         _uri_origin,
         _locale
       ) do
    %{
      id: :submission_form,
      title: dgettext("link-advert", "tabbar.item.submission"),
      forward_title: dgettext("link-advert", "tabbar.item.submission.forward"),
      type: :fullpage,
      live_component: Advert.SubmissionView,
      props: %{
        entity: submission,
        user: user
      }
    }
  end

  defp create_tab(
         :funding,
         %{assignment: assignment, submission: submission},
         _show_errors,
         user,
         _uri_origin,
         locale
       ) do
    %{
      id: :funding,
      title: dgettext("link-advert", "tabbar.item.funding"),
      forward_title: dgettext("link-advert", "tabbar.item.funding.forward"),
      type: :fullpage,
      live_component: Advert.FundingView,
      props: %{
        assignment: assignment,
        submission: submission,
        user: user,
        locale: locale
      }
    }
  end

  defp create_tab(
         :monitor,
         %{assignment: assignment} = advert,
         _show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    attention_list_enabled? = Assignment.Public.attention_list_enabled?(assignment)
    task_labels = Assignment.Public.task_labels(assignment)

    %{
      id: :monitor,
      title: dgettext("link-advert", "tabbar.item.monitor"),
      forward_title: dgettext("link-advert", "tabbar.item.monitor.forward"),
      type: :fullpage,
      live_component: Advert.MonitorView,
      props: %{
        entity: advert,
        attention_list_enabled?: attention_list_enabled?,
        labels: task_labels
      }
    }
  end
end
