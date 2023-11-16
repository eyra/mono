defmodule Systems.Assignment.ExternalPanelController do
  use CoreWeb, :controller

  @supported_locales ~w(nl en)
  @centerdata_callback_url "https://quest.centerdata.nl/eyra/dd.php"

  def create(conn, %{"id" => id, "panel" => panel} = params) do
    []
    |> add_locale(params)
    |> add_panel_info(String.to_existing_atom(panel), params)
    |> start_assignment(conn, id)
  end

  defp add_panel_info(opts, panel, params) do
    panel_info = %{
      callback_url: get_callback_url(panel),
      participant: get_participant(panel, params),
      language: get_language(panel, params),
      query_string: params
    }

    Keyword.put(opts, :panel_info, panel_info)
  end

  defp add_locale(opts, %{"locale" => locale}), do: add_locale(opts, locale)
  defp add_locale(opts, %{"lang" => locale}), do: add_locale(opts, locale)

  defp add_locale(opts, locale) when is_binary(locale) do
    if is_supported?(locale) do
      Keyword.put(opts, :locale, locale)
    else
      opts
    end
  end

  defp add_locale(opts, _), do: opts

  defp is_supported?(locale) when is_binary(locale) do
    locale in @supported_locales
  end

  defp start_assignment(_opts, conn, id) do
    path = ~p"/assignment/#{id}"
    redirect(conn, to: path)
  end

  # Param Mappings

  defp get_participant(:liss, %{"respondent" => respondent}), do: respondent
  defp get_participant(_, %{"participant" => participant}), do: participant

  defp get_language(:liss, %{"lang" => lang}), do: lang
  defp get_language(_, %{"language" => language}), do: language

  defp get_callback_url(:liss), do: @centerdata_callback_url
  defp get_callback_url(_), do: nil
end
