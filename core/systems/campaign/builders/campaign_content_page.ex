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
        %{uri_path: uri_path} = assigns,
        url_resolver
      ) do
    submitted? = Map.get(submission, :status, :idle) != :idle
    tabs = create_tabs(campaign, assigns, url_resolver)

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

  defp create_tabs(
         %{
           submission: submission,
           promotion: promotion,
           promotable: assignment
         } = campaign,
         %{current_user: user, uri_origin: uri_origin, validate?: validate?},
         _url_resolver
       ) do
    submitted? = Pool.SubmissionModel.submitted?(submission)
    validate? = validate? or submitted?

    assignment_form_ready? = Assignment.Context.ready?(assignment)
    attention_list_enabled? = Assignment.Context.attention_list_enabled?(assignment)
    task_labels = Assignment.Context.task_labels(assignment)

    promotion_form_ready? = Promotion.Context.ready?(promotion)

    [
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
      },
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
      },
      %{
        id: :criteria_form,
        title: dgettext("link-survey", "tabbar.item.criteria"),
        forward_title: dgettext("link-survey", "tabbar.item.criteria.forward"),
        type: :fullpage,
        component: Pool.CampaignSubmissionView,
        props: %{
          entity: submission,
          user: user
        }
      },
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
    ]
  end

  defp create_tabs(_, _, _), do: []
end
