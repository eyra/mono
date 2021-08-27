defmodule CoreWeb.Support do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :support

  alias Surface.Components.Form
  alias EyraUI.Text.{Title3, BodyLarge}
  alias EyraUI.Spacing
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Form.{TextArea, TextInput}
  alias EyraUI.Text.{Title3}
  alias EyraUI.Button.SubmitButton
  alias Core.Helpdesk

  data(focus, :any, default: nil)
  data(data, :any, default: {})

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:changeset, Helpdesk.new_ticket_changeset())
     |> update_menus()}
  end

  def handle_event(
        "create_ticket",
        %{"ticket" => data},
        %{assigns: %{current_user: user}} = socket
      ) do
    case Helpdesk.create_ticket(user, data) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("eyra-support", "ticket_created.info.flash"))
         |> push_redirect(to: Routes.live_path(socket, CoreWeb.Marketplace))}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("focus", %{"field" => field}, socket) do
    {:noreply, assign(socket, :focus, field)}
  end

  def handle_event("store_state", %{"ticket" => ticket}, socket) do
    {:noreply, assign(socket, :changeset, Helpdesk.new_ticket_changeset(ticket))}
  end

  def render(assigns) do
    ~H"""
    <Workspace
        title={{ dgettext("eyra-support", "title") }}
        menus={{ @menus }}
    >
      <ContentArea>
        <Title3>{{dgettext("eyra-support", "form.title")}}</Title3>
        <BodyLarge>{{dgettext("eyra-support", "form.description")}} </BodyLarge>
        <Spacing value="S" />
        <div x-data="{ focus: '{{@focus}}' }">
          <Form for={{@changeset}} submit="create_ticket" change="store_state">
            <TextInput field={{:title}} label_text={{dgettext("eyra-support", "ticket.title.label")}}  />
              <Spacing value="S" />
            <TextArea field={{:description}} label_text={{dgettext("eyra-support", "ticket.description.label")}}  />

          <SubmitButton label={{ dgettext("eyra-support", "create_ticket.button") }} />
        </Form>
      </div>

      </ContentArea>
    </Workspace>
    """
  end
end
