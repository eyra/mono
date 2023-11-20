defmodule Systems.Assignment.ExternalPanelController do
  use CoreWeb, :controller

  def create(conn, %{"id" => _id, "panel" => _panel} = params) do
    conn
    |> add_panel_info(params)
    |> redirect(to: path(params))
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
