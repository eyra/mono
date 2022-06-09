defmodule Systems.DataDonation.CenterdataFakeApiPage do
  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  data(page, :any)
  data(qu_1, :any)
  data(respondent, :any)
  data(token, :any)
  data(quest, :any)
  data(button_next, :any)

  @impl true
  def mount(
        %{
          "params" => %{
            "qu_1" => qu_1,
            "page" => page,
            "_respondent" => respondent,
            "button_next" => button_next,
            "token" => token,
            "quest" => quest
          }
        } = _params,
        _session,
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        page: page,
        qu_1: qu_1,
        respondent: respondent,
        token: token,
        button_next: button_next,
        quest: quest
      )
    }
  end

  @impl true
  def render(assigns) do
    ~F"""
      <table>
        <tr>
          <td>page:</td>
          <td>{@page}</td>
        </tr>
        <tr>
          <td>_respondent:</td>
          <td>{@respondent}</td>
        </tr>
        <tr>
          <td>button_next:</td>
          <td>{@button_next}</td>
        </tr>
        <tr>
          <td>token:</td>
          <td>{@token}</td>
        </tr>
        <tr>
          <td>quest:</td>
          <td>{@quest}</td>
        </tr>
        <tr>
          <td>qu_1:</td>
          <td>{@qu_1}</td>
        </tr>
      </table>
    """
  end
end
