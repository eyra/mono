defmodule Systems.Storage.Centerdata.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  def store(
        %{
          "url" => url,
          "varname1" => varname1,
          "page" => page,
          "respondent" => respondent,
          "token" => token
        } = _session,
        %{storage_info: %{quest: quest}} = _vm,
        data
      ) do
    body =
      "{\"#{varname1}\": \"#{data}\", \"button_next\": \"Next\", \"page\": \"#{page}\", \"_respondent\": \"#{respondent}\", \"token\": \"#{token}\", \"quest\": \"#{quest}}\""

    post(url, body)
  end

  defp post(url, body) do
    Logger.info("Centerdata post: #{url} => #{body}")
    response = http_request(:post, url, body, [{"Content-type", "application/json"}])
    Logger.info("Centerdata post response status: #{response.status_code}")

    response
  end

  defp http_request(method, url, body, headers, options \\ []) do
    http_client().request!(method, url, body, headers, options)
  end

  defp http_client() do
    Application.get_env(
      :core,
      :data_donation_http_client,
      Frameworks.Utility.HTTPClient
    )
  end
end
