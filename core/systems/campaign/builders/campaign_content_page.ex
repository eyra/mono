defmodule Systems.Campaign.Builders.CampaignContentPage do
  import CoreWeb.Gettext

  require Link.Enums.Themes
  alias Link.Enums.Themes

  alias Systems.{
    Campaign,
    Assignment,
    Promotion,
    Pool
  }

  def view_model(
        %Campaign.Model{} = campaign,
        assigns,
        url_resolver
      ) do
    campaign
    |> Campaign.Model.flatten()
    |> view_model(assigns, url_resolver)
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
          validate?: validate?,
          locale: locale
        },
        url_resolver
      ) do
    submitted? = Pool.SubmissionModel.submitted?(submission)
    validate? = validate? or submitted?

    tabs = create_tabs(campaign, validate?, user, uri_origin, locale)

    preview_path =
      url_resolver.(Promotion.LandingPage, id: promotion_id, preview: true, back: uri_path)

    %{
      id: campaign_id,
      submission: submission,
      promotion: promotion,
      tabs: tabs,
      submitted?: submitted?,
      preview_path: preview_path
    }
  end

  defp create_tabs(campaign, validate?, user, uri_origin, locale) do
    campaign
    |> get_tab_keys()
    |> Enum.map(&create_tab(&1, campaign, validate?, user, uri_origin, locale))
  end

  defp get_tab_keys(%{submission: %{pool: %{currency: %{type: :legal}}}}) do
    [:promotion, :assignment, :funding, :submission, :monitor]
  end

  defp get_tab_keys(_campaign) do
    [:promotion, :assignment, :submission, :monitor]
  end

  defp create_tab(:promotion, %{promotion: promotion}, validate?, _user, _uri_origin, _locale) do
    promotion_form_ready? = Promotion.Public.ready?(promotion)

    %{
      id: :promotion_form,
      ready?: !validate? || promotion_form_ready?,
      title: dgettext("link-survey", "tabbar.item.promotion"),
      forward_title: dgettext("link-survey", "tabbar.item.promotion.forward"),
      type: :fullpage,
      component: Promotion.FormView,
      props: %{
        entity: promotion,
        validate?: validate?,
        themes_module: Themes
      }
    }
  end

  defp create_tab(:assignment, %{promotable: assignment}, validate?, user, uri_origin, _locale) do
    assignment_form_ready? = Assignment.Public.ready?(assignment)

    %{
      id: :assignment_form,
      ready?: !validate? || assignment_form_ready?,
      title: dgettext("link-survey", "tabbar.item.assignment"),
      forward_title: dgettext("link-survey", "tabbar.item.assignment.forward"),
      type: :fullpage,
      component: Assignment.AssignmentForm,
      props: %{
        entity: assignment,
        uri_origin: uri_origin,
        validate?: validate?,
        user: user,
        target: self()
      }
    }
  end

  defp create_tab(:submission, %{submission: submission}, _validate?, user, _uri_origin, _locale) do
    %{
      id: :submission_form,
      title: dgettext("link-survey", "tabbar.item.submission"),
      forward_title: dgettext("link-survey", "tabbar.item.submission.forward"),
      type: :fullpage,
      component: Pool.CampaignSubmissionView,
      props: %{
        entity: submission,
        user: user
      }
    }
  end

  defp create_tab(
         :funding,
         %{promotable: assignment, submission: submission},
         _validate?,
         user,
         _uri_origin,
         locale
       ) do
    %{
      id: :funding,
      title: dgettext("link-survey", "tabbar.item.funding"),
      forward_title: dgettext("link-survey", "tabbar.item.funding.forward"),
      type: :fullpage,
      component: Campaign.FundingView,
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
         _validate?,
         _user,
         _uri_origin,
         _locale
       ) do
    attention_list_enabled? = Assignment.Public.attention_list_enabled?(assignment)
    task_labels = Assignment.Public.task_labels(assignment)

    %{
      id: :monitor,
      title: dgettext("link-survey", "tabbar.item.monitor"),
      forward_title: dgettext("link-survey", "tabbar.item.monitor.forward"),
      type: :fullpage,
      component: Campaign.MonitorView,
      props: %{
        entity: campaign,
        attention_list_enabled?: attention_list_enabled?,
        labels: task_labels
      }
    }
  end
end
