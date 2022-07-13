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

  alias Core.Accounts

  alias Phoenix.LiveView
  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Form.{Form, TextInput, TextArea}
  alias Frameworks.Pixel.Button.SubmitButton
  use Bamboo.Phoenix, view: Systems.Email.EmailView

  alias Systems.{
    Email
  }

  prop(user, :map)

  data(to, :string)
  data(subject, :string)
  data(message, :string)
  data(focus, :any, default: "")
  data(changeset, :any)

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(%{id: id, user: user} = params, socket) do
    {:ok,
     socket
     |> LiveView.assign(:id, id)
     |> LiveView.assign(user: user)
     |> LiveView.assign(:changeset, changeset(params))}
  end

  @impl true
  def handle_event(
        "update",
        %{"debug_model" => mail_data},
        socket
      ) do
    {:noreply, LiveView.assign(socket, :changeset, changeset(mail_data))}
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
          to_user = Accounts.get_user_by_email(to)

          send_mail(subject, message, from_user, to_user)
          changeset(%{})

        changeset ->
          changeset
      end

    {
      :noreply,
      Phoenix.LiveView.assign(socket, :changeset, changeset)
    }
  end

  @impl true
  def render(assigns) do
    ~F"""
    <ContentArea>
      <Title2>Email</Title2>
      <Form
        id="mail_form"
        changeset={@changeset}
        change_event="update"
        submit="send"
        target={@myself}
        focus={@focus}
      >
        <TextInput field={:to} label_text="To" />
        <TextInput field={:subject} label_text="Subject" />
        <TextArea field={:message} label_text="Message" />
        <SubmitButton label="Send" />
      </Form>
    </ContentArea>
    """
  end

  defp changeset(params) do
    %Systems.Email.DebugModel{}
    |> cast(params, [:to, :subject, :message])
  end

  defp send_mail(subject, message, from_user, to_user) do
    Accounts.Email.debug(subject, message, from_user, to_user)
    |> Email.Context.deliver_now!()
  end
end
