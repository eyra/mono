defmodule Systems.Assignment.ExternalPanelController do
  use CoreWeb, :controller

  alias Systems.Assignment
  alias Systems.Crew

  require Logger

  def create(conn, %{"id" => id, "panel" => _} = params) do
    assignment = Assignment.Public.get!(id, [:crew, :auth_node])

    Logger.warn("[ExternalPanelController] create: #{inspect(params)}")

    cond do
      has_no_access?(assignment, params) -> forbidden(conn)
      is_offline?(assignment) -> service_unavailable(conn)
      true -> start(assignment, conn, params)
    end
  end

  defp is_offline?(%{status: status}) do
    status != :online
  end

  defp has_no_access?(%{external_panel: external_panel}, %{"panel" => panel}) do
    external_panel = Atom.to_string(external_panel)
    external_panel != panel
  end

  defp start(%{external_panel: panel} = assignment, conn, params) do
    participant_id = get_participant(params)

    conn
    |> ExternalSignIn.sign_in(panel, participant_id)
    |> authorize_user(assignment)
    |> add_panel_info(params)
    |> redirect(to: path(params))
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
      participant: get_participant(params),
      query_string: params
    }

    conn |> put_session(:panel_info, panel_info)
  end

  defp path(%{"id" => id} = params) do
    query_string = query_string(params)
    "/assignment/#{id}#{query_string}"
  end

  defp query_string(params) do
    if locale = get_locale(params) do
      "?locale=#{locale}"
    else
      ""
    end
  end

  # @supported_locales ~w(nl en)
  # defp is_supported?(locale) when is_binary(locale) do
  #   locale in @supported_locales
  # end

  # Param Mappings

  defp get_participant(%{"respondent" => respondent}), do: respondent
  defp get_participant(%{"participant" => participant}), do: participant
  defp get_participant(_), do: nil

  defp get_locale(%{"lang" => lang}), do: lang
  defp get_locale(%{"language" => language}), do: language
  defp get_locale(%{"locale" => locale}), do: locale
  defp get_locale(_), do: nil
end
