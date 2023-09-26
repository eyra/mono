defmodule Systems.Citizen.Pool.SubmissionPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias Systems.{
    Pool,
    Campaign
  }

  def view_model(%Pool.SubmissionModel{} = submission, _assigns) do
    %{promotion: promotion} =
      campaign = Campaign.Public.get_by_submission(submission, [:promotion])

    owners = Campaign.Public.list_owners(campaign, [:profile, :features])
    owner = List.first(owners)
    member = Pool.Builders.ResearcherItem.view_model(owner, promotion)

    accepted? = submission.status == :accepted
    completed? = submission.status == :completed
    validate? = accepted? or completed?

    update_at =
      campaign.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path = ~p"/promotion/#{promotion.id}?preview=true"

    excluded_campaigns =
      Campaign.Public.list_excluded_campaigns([campaign], Campaign.Model.preload_graph(:down))
      |> Enum.map(&Campaign.Model.flatten(&1))
      |> Enum.map(&Pool.Builders.CampaignItem.view_model(&1))

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
end
