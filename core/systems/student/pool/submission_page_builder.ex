defmodule Systems.Student.Pool.SubmissionPageBuilder do
  @moduledoc false
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Systems.Advert
  alias Systems.Pool
  alias Systems.Student

  def view_model(%Pool.SubmissionModel{} = submission, %{current_user: user}) do
    %{promotion: promotion} = advert = Advert.Public.get_by_submission(submission, [:promotion])

    owners = Advert.Public.list_owners(advert, [:profile, :features])
    owner = List.first(owners)
    member = Pool.ResearcherItemBuilder.view_model(owner, promotion)

    accepted? = submission.status == :accepted
    completed? = submission.status == :completed
    validate? = accepted? or completed?

    update_at =
      advert.updated_at
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()

    byline = dgettext("eyra-submission", "byline", timestamp: update_at)

    preview_path = ~p"/promotion/#{promotion.id}?preview=true"

    excluded_adverts =
      [advert]
      |> Advert.Public.list_excluded_adverts(Advert.Model.preload_graph(:down))
      |> Enum.map(&Pool.AdvertItemBuilder.view_model(&1))

    form = %{
      live_component: Student.Pool.SubmissionForm,
      props: %{entity: submission, user: user}
    }

    %{
      form: form,
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
