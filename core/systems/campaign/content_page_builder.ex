defmodule Systems.Campaign.Builders.CampaignContentPage do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Assignment,
    Promotion,
    Pool
  }

  require Campaign.Themes
  alias Campaign.Themes

  def view_model(
        %Campaign.Model{} = campaign,
        assigns
      ) do
    campaign
    |> Campaign.Model.flatten()
    |> view_model(assigns)
  end

  def view_model(
        %{
          id: campaign_id,
          submission: submission,
          promotion:
            %{
              id: promotion_id
            } = promotion
        } = campaign,
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

    tabs = create_tabs(campaign, show_errors, user, uri_origin, locale)
    preview_path = ~p"/promotion/#{promotion_id}?preview=true&back=#{uri_path}"

    %{
      title: dgettext("link-campaign", "content.title"),
      id: campaign_id,
      submission: submission,
      promotion: promotion,
      tabs: tabs,
      submitted?: submitted?,
      show_errors: show_errors,
      preview_path: preview_path
    }
  end

  defp create_tabs(campaign, show_errors, user, uri_origin, locale) do
    campaign
    |> get_tab_keys()
    |> Enum.map(&create_tab(&1, campaign, show_errors, user, uri_origin, locale))
  end

  defp get_tab_keys(%{submission: %{pool: %{currency: %{type: :legal}}}}) do
    [:promotion, :assignment, :funding, :submission, :monitor]
  end

  defp get_tab_keys(_campaign) do
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
      title: dgettext("link-campaign", "tabbar.item.promotion"),
      forward_title: dgettext("link-campaign", "tabbar.item.promotion.forward"),
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
         %{promotable: assignment},
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
      title: dgettext("link-campaign", "tabbar.item.assignment"),
      forward_title: dgettext("link-campaign", "tabbar.item.assignment.forward"),
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
      title: dgettext("link-campaign", "tabbar.item.submission"),
      forward_title: dgettext("link-campaign", "tabbar.item.submission.forward"),
      type: :fullpage,
      live_component: Pool.CampaignSubmissionView,
      props: %{
        entity: submission,
        user: user
      }
    }
  end

  defp create_tab(
         :funding,
         %{promotable: assignment, submission: submission},
         _show_errors,
         user,
         _uri_origin,
         locale
       ) do
    %{
      id: :funding,
      title: dgettext("link-campaign", "tabbar.item.funding"),
      forward_title: dgettext("link-campaign", "tabbar.item.funding.forward"),
      type: :fullpage,
      live_component: Campaign.FundingView,
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
         %{promotable: assignment} = campaign,
         _show_errors,
         _user,
         _uri_origin,
         _locale
       ) do
    attention_list_enabled? = Assignment.Public.attention_list_enabled?(assignment)
    task_labels = Assignment.Public.task_labels(assignment)

    %{
      id: :monitor,
      title: dgettext("link-campaign", "tabbar.item.monitor"),
      forward_title: dgettext("link-campaign", "tabbar.item.monitor.forward"),
      type: :fullpage,
      live_component: Campaign.MonitorView,
      props: %{
        entity: campaign,
        attention_list_enabled?: attention_list_enabled?,
        labels: task_labels
      }
    }
  end
end
