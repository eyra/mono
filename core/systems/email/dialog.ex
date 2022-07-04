defmodule Systems.Email.Dialog do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title2}

  alias Systems.{
    Email
  }

  prop(users, :list, required: true)
  prop(current_user, :map, required: true)

  data(close_button, :map)

  def update(
        %{
          id: id,
          users: users,
          current_user: current_user
        },
        %{assigns: %{myself: myself}} = socket
      ) do
    close_button = %{
      action: %{type: :send, event: "close", target: myself},
      face: %{type: :icon, icon: :close}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        users: users,
        current_user: current_user,
        close_button: close_button
      )
    }
  end

  @impl true
  def handle_event("close", _unsigned_params, socket) do
    {:noreply, update_parent(socket, :close)}
  end

  @impl true
  def handle_event("reset_focus", _unsigned_params, socket) do
    send_update(Email.Form, id: :email_form, focus: "")
    {:noreply, socket}
  end

  defp update_parent(socket, message) do
    send(self(), {:email_dialog, message})
    socket
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div
      class="min-w-1/2 max-w-9/10 sm:max-w-3/4 p-8 bg-white shadow-2xl rounded"
      phx-click="reset_focus"
      phx-target={@myself}
    >
      <div class="">
        <div class="flex flex-row">
          <div class="flex-grow" />
          <DynamicButton vm={@close_button} />
        </div>
        <Spacing value="S" />
        <Title2>{dgettext("eyra-email", "dialog.title")}</Title2>
        <Email.Form id={:email_form} users={@users} from_user={@current_user} />
      </div>
    </div>
    """
  end
end

defmodule Systems.Email.Dialog.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Email.Dialog,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Email dialog",
    height: "1024px",
    direction: "horizontal",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <Dialog
      id={:email_dialog_example}
      users={[
        %{email: "e.vanderveen@eyra.co", profile: %{fullname: "Emiel van der Veen"}},
        %{email: "a.m.mendrik@eyra.co", profile: %{fullname: "Adrienne Mendrik"}},
        %{email: "emielvdveen@gmail.com", profile: %{fullname: "Emiel van der Veen"}},
        %{email: "pietje.puk@gmail.com", profile: %{fullname: "Pietje Puk"}},
        %{email: "jantje.paardehaar@gmail.com", profile: %{fullname: "Jantje Paardehaar"}},
        %{email: "jantje.smid@gmail.com", profile: %{fullname: "Jantje Smid"}}
      ]}
      current_user={%{email: "admin@eyra.co", displayname: "Ad Min"}}
    />
    """
  end

  def handle_info({:email_dialog, :close}, socket) do
    IO.puts("Close")
    {:noreply, socket}
  end

  def handle_info({:claim_focus, :email_form}, socket) do
    IO.puts("Claim focus")
    {:noreply, socket}
  end
end
