defmodule Systems.Storage.Centerdata.Form do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(
        %{
          request: %{
            url: url,
            data: data,
            varname1: varname1,
            page: page,
            respondent: respondent,
            token: token,
            button_next: button_next,
            quest: quest
          }
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        url: url,
        data: data,
        varname1: varname1,
        page: page,
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
      <form id="centerdata-form" phx-hook="AutoSubmit" class="hidden" action={@url} method="post">
        <input type="hidden" name={@varname1} value={@data} id="data">
        <input type="hidden" name="page" value={@page}>
        <input type="hidden" name="_respondent" value={@respondent}>
        <input type="hidden" name="token" value={@token}>
        <input type="hidden" name="button_next" value={@button_next}>
        <input type="hidden" name="quest" value={@quest}>
      </form>
    """
  end
end
