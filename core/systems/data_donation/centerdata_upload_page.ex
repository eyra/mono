defmodule Systems.DataDonation.CenterdataUploadPage do
  defmodule StoreResultsError do
    @moduledoc false
    defexception [:message]
  end

  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  data(page, :any)
  data(varname1, :any)
  data(respondent, :any)
  data(token, :any)
  data(quest, :any)
  data(button_next, :any)
  data(data, :any)

  @impl true
  def mount(
        %{
          "session" => %{
            "page" => page,
            "varname1" => varname1,
            "respondent" => respondent,
            "token" => token,
            "url" => url
          }
        } = _params,
        _session,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        url: url,
        page: page,
        varname1: varname1,
        respondent: respondent,
        token: token,
        button_next: "Verder",
        data: "{\"some_key\": \"some_value\"}",
        quest: "test_arnaud"
      )
    }
  end

  @impl true
  def render(assigns) do
    ~F"""
    <form action={@url} method="post">
      <div class="content">
        <input value={@page} name="page">
        <input value={@data} name={@varname1}>
        <input value={@respondent} name="_respondent">
        <input value={@token} name="token">
        <input value={@quest} name="quest">
        <input value={@button_next} name="button_next">
      </div>
      <div class="buttons">
        <div class="next_button">
          <input type="submit" value="Verder" name="button_next" class="button" id="button_next">
        </div>
      </div>
    </form>
    """
  end
end
