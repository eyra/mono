defmodule Systems.Support.HelpdeskPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :helpdesk

  import CoreWeb.Layouts.Workspace.Component

  alias Systems.Support.HelpdeskForm

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> update_menus()}
  end

  def handle_info({:claim_focus, :helpdesk_form}, socket) do
    # helpdesk_form is currently only form that can claim focus
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace menus={@menus}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-support", "form.title") %></Text.title2>
          <Text.body_large><%= dgettext("eyra-support", "form.description") %>
          </Text.body_large>
        </Area.form>
      </Area.content>

      <.spacing value="XL" />

      <.live_component module={HelpdeskForm} id={:helpdesk_form} user={@current_user} />
    </.workspace>
    """
  end
end
