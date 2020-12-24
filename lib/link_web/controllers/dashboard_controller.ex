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
    available_count = Enum.count(available_studies)

    highlighted_studies = [{"owned", owned_studies}, {"participations", study_participations}]
    highlighted_count = Enum.count(exclusion_list)

    render(conn, "index.html",
      active_tab: "owned",
      highlighted_studies: highlighted_studies,
      highlighted_count: highlighted_count,
      available_studies: available_studies,
      available_count: available_count
    )
  end
end
