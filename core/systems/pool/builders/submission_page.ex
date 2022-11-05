defmodule Systems.Pool.Builders.SubmissionPage do
  import CoreWeb.Gettext

  alias Core.Accounts.User

  alias Systems.{
    Pool,
    Campaign,
    Promotion
  }

  def view_model(submission, _assigns, url_resolver) do
    %{promotion: promotion} =
      campaign =
      Campaign.Context.get_by_submission(submission, Campaign.Model.preload_graph(:full))

    owners = Campaign.Context.list_owners(campaign, [:profile, :features])
    owner = List.first(owners)
    member = to_member(owner, promotion)

    accepted? = submission.status == :accepted
    completed? = submission.status == :completed
    validate? = accepted? or completed?

    update_at =
      campaign.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path = url_resolver.(Promotion.LandingPage, id: promotion.id, preview: true)

    excluded_campaigns =
      Campaign.Context.list_excluded_campaigns([campaign], Campaign.Model.preload_graph(:full))
      |> Enum.map(&Campaign.Model.flatten(&1))
      |> Enum.map(&Pool.Builders.CampaignItem.view_model(url_resolver, &1))

    %{
      member: member,
      submission: submission,
      promotion_id: promotion.id,
      campaign_id: campaign.id,
      excluded_campaigns: excluded_campaigns,
      title: promotion.title,
      byline: byline,
      accepted?: accepted?,
      completed?: completed?,
      validate?: validate?,
      preview_path: preview_path
    }
  end

  defp to_member(
         %{
           email: email,
           profile: %{
             fullname: fullname,
             photo_url: photo_url
           }
         } = user,
         %{
           title: title
         }
       ) do
    role = dgettext("eyra-admin", "role.researcher")
    action = %{type: :href, href: "mailto:#{email}?subject=Re: #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: User.get_gender(user),
      button_large: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-ui", "mailto.button"),
          bg_color: "bg-tertiary",
          text_color: "text-grey1"
        }
      },
      button_small: %{
        action: action,
        face: %{type: :icon, icon: :contact, color: :tertiary}
      }
    }
  end
end
