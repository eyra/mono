defmodule Systems.Assignment.Centerdata.FakeApiPage do
  use CoreWeb, :live_view
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  import Phoenix.Component

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
    ~H"""
    <table>
      <tr>
        <td>page:</td>
        <td><%= @page %></td>
      </tr>
      <tr>
        <td>_respondent:</td>
        <td><%= @respondent %></td>
      </tr>
      <tr>
        <td>button_next:</td>
        <td><%= @button_next %></td>
      </tr>
      <tr>
        <td>token:</td>
        <td><%= @token %></td>
      </tr>
      <tr>
        <td>quest:</td>
        <td><%= @quest %></td>
      </tr>
      <tr>
        <td>qu_1:</td>
        <td><%= @qu_1 %></td>
      </tr>
    </table>
    """
  end
end
