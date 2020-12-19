defmodule LinkWeb.DashboardController do
  use LinkWeb, :controller

  alias Link.Studies

  def index(conn, _params) do
    user = conn |> Pow.Plug.current_user()
    # user |> Studies.list_owned_studies()
    owned_studies = user |> Studies.list_owned_studies()
    study_participations = user |> Studies.list_participations()

    exclusion_list =
      Stream.concat(owned_studies, study_participations)
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies = Studies.list_studies(exclude: exclusion_list)

    selected_studies = [{"owned", owned_studies}, {"participations", study_participations}]

    render(conn, "index.html",
      selected_studies_tab: "owned",
      selected_studies: selected_studies,
      available_studies: available_studies
    )
  end
end
