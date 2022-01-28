defmodule Systems.DataDonation.ThanksPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped

  alias Systems.DataDonation

  data(tool, :any)

  def mount(%{"id" => tool_id}, _session, socket) do
    tool = DataDonation.Context.get!(tool_id)

    {:ok, assign(socket, tool: tool) |> update_menus()}
  end

  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
    Thanks
    </Stripped>
    """
  end
end
