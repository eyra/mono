defmodule Self.User.Signin do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :signin

  alias Core.Accounts.User
  alias CoreWeb.User.Form

  def mount(params, _session, socket) do
    require_feature(:password_sign_in)

    {
      :ok,
      socket
      |> assign(email: Map.get(params, "email"))
      |> update_form()
    }
  end

  defp update_form(%{assigns: %{email: nil}} = socket) do
    assign(socket, :form, to_form(%{}))
  end

  defp update_form(%{assigns: %{email: email}} = socket) when is_binary(email) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email}
      else
        %{}
      end

    assign(socket, :form, to_form(attrs))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "signin.title") %></Text.title2>
          <div>
            <Form.password_signin for={@form} />
          </div>
          <.spacing value="M" />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
