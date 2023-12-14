defmodule Systems.Storage.Centerdata.Backend do
  @behaviour Systems.Storage.Backend

  require Logger

  def store(
        %{url: url} = _endpoint,
        %{
          query_string: %{
            "quest" => quest,
            "varname1" => varname1,
            "respondent" => respondent,
            "token" => token,
            "page" => page
          }
        } = _panel_info,
        data,
        _meta_data
      ) do
    Logger.warn("Centerdata store: respondent=#{respondent}")

    request = %{
      url: url,
      data: data,
      varname1: varname1,
      button_next: "Next",
      page: page,
      respondent: respondent,
      token: token,
      quest: quest
    }

    form = %{
      id: :centerdata_form,
      module: Systems.Storage.Centerdata.Form,
      params: %{
        request: request
      }
    }

    send(self(), %{storage_event: %{panel: :centerdata, form: form}})
  end
end
