defmodule Systems.Assignment.ExternalPanelController do
  use CoreWeb, :controller

  alias Systems.Assignment
  alias Systems.Crew

  require Logger

  def create(conn, %{"id" => id, "entry" => _} = params) do
    assignment = Assignment.Public.get!(id, [:crew, :auth_node])

    Logger.warn("[ExternalPanelController] create: #{inspect(params)}")

    if tester?(assignment, conn) do
      conn
      |> add_panel_info(params)
      |> redirect(to: path(params))
    else
      cond do
        has_no_access?(assignment, params) -> forbidden(conn)
        offline?(assignment) -> service_unavailable(conn)
        true -> start(assignment, conn, params)
      end
    end
  end

  defp tester?(assignment, %{assigns: %{current_user: %{} = user}}) do
    Assignment.Public.tester?(assignment, user)
  end

  defp tester?(_, _), do: false

  defp offline?(%{status: status}) do
    status != :online
  end

  defp has_no_access?(%{external_panel: external_panel}, params) do
    external_panel = Atom.to_string(external_panel)
    external_panel != get_panel(params)
  end

  defp start(%{external_panel: external_panel} = assignment, conn, params) do
    participant_id = get_participant(params)

    conn
    |> ExternalSignIn.sign_in(external_panel, participant_id)
    |> authorize_user(assignment)
    |> add_panel_info(params)
    |> CoreWeb.LanguageSwitchController.index(%{
      "locale" => get_locale(params),
      "redir" => path(params)
    })
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"403")
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"503")
  end

  defp authorize_user(%{assigns: %{current_user: user}} = conn, %{crew: crew}) do
    if not Crew.Public.member?(crew, user) do
      Crew.Public.apply_member_with_role(crew, user, :participant)
    end

    conn
  end

  defp add_panel_info(conn, params) do
    panel_info = %{
      panel: get_panel(params),
      embedded?: embedded?(params),
      participant: get_participant(params),
      query_string: params
    }

    conn |> put_session(:panel_info, panel_info)
  end

  defp path(%{"id" => id} = params) do
    query_string = query_string(params)
    "/assignment/#{id}#{query_string}"
  end

  defp query_string(_params) do
    ""
    # if locale = get_locale(params) do
    #   "?locale=#{locale}"
    # else
    #   ""
    # end
  end

  # Param Mappings

  defp get_panel(%{"entry" => "participate"}), do: "generic"
  defp get_panel(%{"entry" => entry}), do: entry

  defp get_participant(%{"respondent" => respondent}), do: respondent
  defp get_participant(%{"participant" => participant}), do: participant
  defp get_participant(_), do: nil

  # Liss should always be in dutch
  defp get_locale(%{"entry" => "liss"}), do: "nl"
  defp get_locale(%{"lang" => lang}), do: lang
  defp get_locale(%{"language" => language}), do: language
  defp get_locale(%{"resolved_locale" => locale}), do: locale
  defp get_locale(_), do: nil

  defp embedded?(%{"entry" => "liss"}), do: true
  defp embedded?(_), do: false
end
