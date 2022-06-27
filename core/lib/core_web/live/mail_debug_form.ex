defmodule CoreWeb.Mail.Forms.DebugSchema do
  use Ecto.Schema

  embedded_schema do
    field(:to, :string)
    field(:subject, :string)
    field(:message, :string)
  end
end

defmodule CoreWeb.Mail.Forms.Debug do
  use CoreWeb.LiveForm
  import Ecto.Changeset

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Form.{Form, TextInput, TextArea}
  alias Frameworks.Pixel.Button.SubmitButton
  use Bamboo.Phoenix, view: Core.Mailer.EmailView
  import Core.Mailer, only: [base_email: 0, deliver_now!: 1]

  data(to, :string)
  data(subject, :string)
  data(message, :string)
  data(focus, :any, default: "")
  data(changeset, :any)

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(%{id: id} = params, socket) do
    {:ok,
     socket
     |> Phoenix.LiveView.assign(:id, id)
     |> Phoenix.LiveView.assign(:changeset, changeset(params))}
  end

  @impl true
  def handle_event(
        "update",
        %{"debug_schema" => mail_data},
        socket
      ) do
    {:noreply, Phoenix.LiveView.assign(socket, :changeset, changeset(mail_data))}
  end

  @impl true
  def handle_event(
        "send",
        %{"debug_schema" => mail_data},
        socket
      ) do
    changeset =
      case changeset(mail_data) do
        %{valid?: true, changes: %{to: to, subject: subject, message: message}} ->
          send_mail(to, subject, message)
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
      <Title2>Mail</Title2>
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
    %CoreWeb.Mail.Forms.DebugSchema{}
    |> cast(params, [:to, :subject, :message])
  end

  defp send_mail(to, subject, message) do
    base_email()
    |> to(to)
    |> subject(subject)
    |> Map.put(:text_body, message)
    |> Map.put(:html_body, message)
    |> deliver_now!()
  end
end
