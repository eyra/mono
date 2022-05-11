defmodule Systems.DataDonation.CenterdataController do
  use CoreWeb, :controller

  def create(
        conn,
        %{
          "error1" => error1,
          "id" => id,
          "lang" => lang,
          "mobile" => mobile,
          "page" => page,
          "questiontext1" => questiontext1,
          "respondent" => respondent,
          "token" => token,
          "url" => url,
          "varname1" => varname1,
          "varvalue1" => varvalue1
        }
      ) do
    session = %{
      url: url,
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

    path = Routes.live_path(conn, Systems.DataDonation.UploadPage, id, session: session)
    redirect(conn, to: path)
  end
end
