defmodule Systems.DataDonation.CenterdataController do
  use CoreWeb, :controller

  alias Systems.{
    DataDonation
  }

  def create(
        conn,
        %{
          "id" => id,
          "url" => url,
          "page" => page,
          "varname1" => varname1,
          "varvalue1" => varvalue1,
          "questiontext1" => questiontext1,
          "error1" => error1,
          "respondent" => respondent,
          "mobile" => mobile,
          "lang" => lang,
          "token" => token
        }
      ) do
    storage_info = %{
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

    conn
    |> live_render(
      DataDonation.UploadPage,
      session: %{
        "flow" => id,
        "storage_info" => storage_info
      }
    )
  end
end
