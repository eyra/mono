defmodule Systems.Email.DebugModel do
  use Ecto.Schema

  embedded_schema do
    field(:to, :string)
    field(:subject, :string)
    field(:message, :string)
  end
end

defmodule Systems.Email.DebugForm do
  use CoreWeb.LiveForm

  import Ecto.Changeset

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.Account
  alias Systems.Email

  # Handle update from parent after auto-save, prevents overwrite of current state
  @impl true
  def update(%{id: id, user: user} = params, socket) do
    {:ok,
     socket
     |> assign(:id, id)
     |> assign(user: user)
     |> assign(:changeset, changeset(params))}
  end

  @impl true
  def handle_event(
        "update",
        %{"debug_model" => mail_data},
        socket
      ) do
    {:noreply, assign(socket, :changeset, changeset(mail_data))}
  end

  @impl true
  def handle_event(
        "send",
        %{"debug_model" => mail_data},
        %{assigns: %{user: from_user}} = socket
      ) do
    changeset =
      case changeset(mail_data) do
        %{valid?: true, changes: %{to: to, subject: subject, message: message}} ->
          to_user = Account.Public.get_user_by_email(to)

          send_mail(subject, message, from_user, to_user)
          changeset(%{})

        changeset ->
          changeset
      end

    {
      :noreply,
      assign(socket, :changeset, changeset)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Text.title2>Email</Text.title2>
      <.form id="mail_form" :let={form} for={@changeset} phx-change="update" phx-submit="send" phx-target={@myself}>
        <.text_input form={form} field={:to} label_text="To" />
        <.text_input form={form} field={:subject} label_text="Subject" />
        <.text_area form={form} field={:message} label_text="Message" />
        <Button.submit label="Send" />
      </.form>
      </Area.content>
    </div>
    """
  end

  defp changeset(params) do
    %Systems.Email.DebugModel{}
    |> cast(params, [:to, :subject, :message])
  end

  defp send_mail(subject, message, from_user, to_user) do
    Email.Factory.debug(subject, message, from_user, to_user)
    |> Email.Public.deliver_now!()
  end
end
