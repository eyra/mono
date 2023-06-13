defmodule Next.User.Signin do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :signin

  alias Core.Accounts
  alias Core.Accounts.User
  alias CoreWeb.User.Form

  def mount(_params, _session, socket) do
    require_feature(:password_sign_in)
    changeset = Accounts.change_user_registration(%User{})

    {:ok,
     socket
     |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event(
        "toggle",
        %{"checkbox" => checkbox},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    field = String.to_atom(checkbox)

    new_value =
      case Ecto.Changeset.fetch_field(changeset, field) |> IO.inspect(label: "FETCH") do
        :error -> true
        value -> not value
      end

    changeset =
      Ecto.Changeset.cast(changeset, %{field => new_value}, [field]) |> IO.inspect(label: "OEPS")

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Accounts.change_user_registration(%User{}, attrs)
    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped user={@current_user} menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "signin.title") %></Text.title2>
          <div>
            <Form.password_signin />
          </div>
          <.spacing value="M" />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
