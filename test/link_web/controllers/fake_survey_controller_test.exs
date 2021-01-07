defmodule LinkWeb.FakeSurveyControllerTest do
  use LinkWeb.ConnCase

  describe "index" do
    test "the link back to the survey tool is shown when a redirect url is provided", %{
      conn: conn
    } do
      redirect_url = "https://#{Faker.Internet.domain_name()}/survey"
      conn = get(conn, Routes.fake_survey_path(conn, :index), redirect_url: redirect_url)

      assert html_response(conn, 200) =~ redirect_url
    end
  end
end
