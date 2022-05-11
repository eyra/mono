defmodule Systems.DataDonation.CenterdataController do
  use CoreWeb, :controller

  def create(
        conn,
        %{
          "error1" => error1,
          "id" => _id,
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

    # data = "{\"some_key\": \"some_value\"}"

    # conn
    # |> render("upload.html",
    #   url: url,
    #   varname1: varname1,
    #   respondent: respondent,
    #   page: page,
    #   token: token,
    #   quest: "test_arnaud",
    #   button_next: "Verder",
    #   data: data
    # )

    path = Routes.live_path(conn, Systems.DataDonation.CenterdataUploadPage, session: session)
    redirect(conn, to: path)
  end
end
