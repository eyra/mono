defmodule Systems.Citizen.Pool.SubmissionPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  alias Systems.{
    Pool,
    Advert
  }

  def view_model(%Pool.SubmissionModel{} = submission, _assigns) do
    %{promotion: promotion} = advert = Advert.Public.get_by_submission(submission, [:promotion])

    owners = Advert.Public.list_owners(advert, [:profile, :features])
    owner = List.first(owners)
    member = Pool.ResearcherItemBuilder.view_model(owner, promotion)

    accepted? = submission.status == :accepted
    completed? = submission.status == :completed
    validate? = accepted? or completed?

    update_at =
      advert.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path = ~p"/promotion/#{promotion.id}?preview=true"

    excluded_adverts =
      Advert.Public.list_excluded_adverts([advert], Advert.Model.preload_graph(:down))
      |> Enum.map(&Pool.AdvertItemBuilder.view_model(&1))

    %{
      member: member,
      submission: submission,
      promotion_id: promotion.id,
      advert_id: advert.id,
      excluded_adverts: excluded_adverts,
      title: promotion.title,
      byline: byline,
      accepted?: accepted?,
      completed?: completed?,
      validate?: validate?,
      preview_path: preview_path
    }
  end
end
