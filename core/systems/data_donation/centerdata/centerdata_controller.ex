defmodule Systems.DataDonation.CenterdataController do
  use CoreWeb, :controller

  @supported_locales ~w(nl en)
  @url "https://quest.centerdata.nl/eyra/dd.php"

  def create(conn, %{"id" => id} = params) do
    []
    |> add_locale(params)
    |> add_session(params)
    |> start_data_donation(conn, id)
  end

  defp add_session(
         opts,
         %{
           "error1" => error1,
           "lang" => lang,
           "mobile" => mobile,
           "page" => page,
           "questiontext1" => questiontext1,
           "respondent" => respondent,
           "token" => token,
           "varname1" => varname1,
           "varvalue1" => varvalue1
         }
       ) do
    session = %{
      url: @url,
      page: page,
      varname1: varname1,
      varvalue1: varvalue1,
      questiontext1: questiontext1,
      error1: error1,
      respondent: respondent,
      mobile: mobile,
      lang: lang,
      token: token
    }

    Keyword.put(opts, :session, session)
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

  defp start_data_donation(_opts, conn, _id) do
    # Routes.live_path(conn, Systems.DataDonation.FlowPage, id, opts)
    path = "/"
    redirect(conn, to: path)
  end
end
