defmodule Systems.Email.Form do
  use CoreWeb.UI.LiveComponent
  import Phoenix.LiveView

  alias Core.Accounts
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Form.{Form, TextInput, TextArea}
  alias Frameworks.Pixel.Button.SubmitButton
  use Bamboo.Phoenix, view: Systems.Email.EmailView

  alias Systems.{
    Email
  }

  prop(users, :list)
  prop(from_user, :map)

  data(subject, :string)
  data(message, :string)
  data(focus, :any)
  data(model, :map)
  data(changeset, :any)
  data(validate?, :boolean)

  # Prevents overwrite of current state
  def update(%{focus: field}, socket) do
    {:ok, socket |> assign(focus: field)}
  end

  # Prevents overwrite of current state
  def update(_params, %{assigns: %{changeset: _}} = socket) do
    {:ok, socket}
  end

  # Handle initial update
  def update(%{id: id, users: users, from_user: %{email: from_email} = from_user}, socket) do
    # send a copy to sender, append email to end of list
    user_emails = users |> Enum.map(& &1.email)
    to = Enum.reverse([from_email | Enum.reverse(user_emails)])

    %{fullname: fullname} = Accounts.get_profile(from_user)
    timestamp = Timestamp.humanize_en(Timestamp.apply_timezone(Timestamp.naive_now()))
    byline = "#{fullname} | #{timestamp}"

    model = %Email.Model{from: from_email, to: to, byline: byline}
    changeset = Email.Model.changeset(:init, model, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        users: users,
        from_user: from_user,
        model: model,
        changeset: changeset,
        validate?: false,
        focus: ""
      )
    }
  end

  @impl true
  def handle_event("focus", %{"field" => field}, socket) do
    {
      :noreply,
      socket |> assign(focus: field)
    }
  end

  @impl true
  def handle_event(
        "update",
        %{"model" => form_data},
        %{assigns: %{model: model, validate?: validate?}} = socket
      ) do
    type =
      if validate? do
        :validate
      else
        :init
      end

    changeset = Email.Model.changeset(type, model, form_data)

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, model} ->
          changeset = Email.Model.changeset(:init, model, %{})
          socket |> assign(model: model, changeset: changeset)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "send",
        %{"model" => form_data},
        %{assigns: %{model: model}} = socket
      ) do
    changeset = Email.Model.changeset(:validate, model, form_data)

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, model} ->
          send(self(), {:email_dialog, model})
          socket |> assign(model: model)

        {:error, %Ecto.Changeset{} = changeset} ->
          socket |> assign(focus: "", changeset: changeset, validate?: true)
      end

    {:noreply, socket}
  end

  defp username(%{profile: %{fullname: fullname}}), do: fullname
  defp username(%{email: email, displayname: nil}), do: String.split(email, "@")
  defp username(%{displayname: displayname}), do: displayname

  defp tags(%{users: users}) when is_list(users) do
    users
    |> Enum.map(&username(&1))
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Form
      id="mail_form"
      changeset={@changeset}
      change_event="update"
      submit="send"
      target={@myself}
      focus={@focus}
    >
      <div class="text-title6 font-title6 leading-snug">{dgettext("eyra-email", "recipients.label")} <span class="text-primary">{Enum.count(@users)}</span></div>
      <Spacing value="XXS" />
      <div class="max-h-mailto overflow-scroll border-2 border-grey3 rounded p-4">
        <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
          <Tag :for={tag <- tags(assigns)} text={tag} />
        </div>
      </div>
      <Spacing value="S" />

      <TextInput field={:title} label_text={dgettext("eyra-email", "title.label")} debounce="0" />
      <TextArea field={:message} label_text={dgettext("eyra-email", "message.label")} debounce="0" />
      <SubmitButton label={dgettext("eyra-email", "send.button")} />
    </Form>
    """
  end
end

defmodule Systems.Email.Form.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Email.Form,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Email Popup",
    height: "1024px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <Form
      id={:email_form_example}
      users={[
        "e.vanderveen@eyra.co",
        "a.m.mendrik@eyra.co",
        "emielvdveen@gmail.com",
        "pietje.puk@gmail.com",
        "jantje.paardehaar@gmail.com",
        "jantje.smid@gmail.com"
      ]}
    />
    """
  end
end
