defmodule Systems.Email.Form do
  use CoreWeb, :live_component

  alias CoreWeb.UI.Timestamp
  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Button
  use Bamboo.Phoenix, component: Systems.Email.EmailHTML

  alias Systems.Account
  alias Systems.Email

  # Prevents overwrite of current state
  @impl true
  def update(_params, %{assigns: %{changeset: _}} = socket) do
    {:ok, socket}
  end

  # Handle initial update
  @impl true
  def update(%{id: id, users: users, from_user: %{email: from_email} = from_user}, socket) do
    # send a copy to sender, append email to end of list
    user_emails = users |> Enum.map(& &1.email)
    to = Enum.reverse([from_email | Enum.reverse(user_emails)])

    %{fullname: fullname} = Account.Public.get_profile(from_user)
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
        validate?: false
      )
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
          socket |> assign(changeset: changeset, validate?: true)
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
    ~H"""
    <.form id="mail_form" :let={form} for={@changeset} phx-change="update" phx-submit="send" phx-target={@myself} >
      <div class="text-title6 font-title6 leading-snug"><%= dgettext("eyra-email", "recipients.label") %> <span class="text-primary"><%= Enum.count(@users) %></span></div>
      <.spacing value="XXS" />
      <div class="max-h-mailto overflow-scroll border-2 border-grey3 rounded p-4">
        <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
          <%= for tag <- tags(assigns) do %>
            <.tag text={tag} />
          <% end %>
        </div>
      </div>
      <.spacing value="S" />

      <.text_input form={form} field={:title} label_text={dgettext("eyra-email", "title.label")} debounce="0" />
      <.text_area form={form} field={:message} label_text={dgettext("eyra-email", "message.label")} debounce="0" />
      <Button.submit label={dgettext("eyra-email", "send.button")} />
    </.form>
    """
  end
end
