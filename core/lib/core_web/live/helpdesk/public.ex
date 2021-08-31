defmodule CoreWeb.Helpdesk.Public do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :helpdesk

  alias EyraUI.Spacing
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Text.{Title2, BodyLarge}

  alias CoreWeb.Helpdesk.Form, as: HelpdeskForm

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> update_menus()}
  end

  def handle_info({:claim_focus, :helpdesk_form}, socket) do
    # helpdesk_form is currently only form that can claim focus
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Workspace
        menus={{ @menus }}
    >
      <ContentArea>
        <FormArea>
          <MarginY id={{:page_top}} />
          <Title2>{{dgettext("eyra-support", "form.title")}}</Title2>
          <BodyLarge>{{dgettext("eyra-support", "form.description")}} </BodyLarge>
        </FormArea>
      </ContentArea>

      <Spacing value="XL" />

      <HelpdeskForm id={{ :helpdesk_form }} user={{ @current_user }}/>
    </Workspace>
    """
  end
end
